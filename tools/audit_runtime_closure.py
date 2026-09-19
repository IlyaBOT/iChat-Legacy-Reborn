#!/usr/bin/env python3
"""
Audit the in-process Mach-O runtime closure of iChat on Snow Leopard.

Designed for Python 3.14 but intentionally uses only the standard library and
Apple command-line tools available on Snow Leopard: otool, nm, file.

What it does:
  * recursively resolves LC_LOAD_* dependencies from the main executable;
  * understands @executable_path, @loader_path and LC_RPATH;
  * follows LC_REEXPORT_DYLIB when calculating provider export surfaces;
  * audits undefined two-level namespace imports of app-local images;
  * reports unresolved libraries, missing symbols, duplicate framework families;
  * optionally checks whether a missing symbol exists in the equivalent Lion
    framework/dylib tree (--lion-root);
  * writes both a human report and machine-readable JSON.

It never modifies binaries.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from collections import defaultdict, deque
from dataclasses import dataclass, field, asdict
from functools import lru_cache
from pathlib import Path
from typing import Iterable

ARCH = "x86_64"
FRAMEWORK_RE = re.compile(r"/([^/]+)\.framework(?:/|$)")
UNDEF_RE = re.compile(r"\(undefined\).*?external\s+(\S+)\s+\(from\s+([^)]+)\)")
LOAD_CMD_RE = re.compile(r"^\s*cmd\s+(LC_[A-Z0-9_]+)\s*$")
NAME_RE = re.compile(r"^\s*name\s+(.+?)\s+\(offset\s+\d+\)\s*$")
PATH_RE = re.compile(r"^\s*path\s+(.+?)\s+\(offset\s+\d+\)\s*$")

LOAD_COMMANDS = {
    "LC_LOAD_DYLIB",
    "LC_LOAD_WEAK_DYLIB",
    "LC_REEXPORT_DYLIB",
    "LC_LOAD_UPWARD_DYLIB",
}


def run(*args: str, check: bool = False) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        args,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        errors="replace",
        check=check,
    )


def real(path: str | Path) -> str:
    return os.path.realpath(os.path.expanduser(str(path)))


def is_macho(path: str) -> bool:
    if not os.path.isfile(path):
        return False
    p = run("file", path)
    return "Mach-O" in p.stdout


@dataclass(frozen=True)
class Dep:
    command: str
    install_name: str
    resolved: str | None


@dataclass
class Image:
    path: str
    deps: list[Dep] = field(default_factory=list)
    rpaths: list[str] = field(default_factory=list)


@dataclass
class Missing:
    consumer: str
    origin: str
    provider_install_name: str | None
    provider_path: str | None
    symbol: str
    kind: str
    lion_provider_path: str | None = None
    present_in_lion: bool | None = None


@dataclass
class Audit:
    executable: str
    app_root: str
    closure: list[str]
    app_local_closure: list[str]
    unresolved_libraries: list[dict]
    missing_symbols: list[Missing]
    duplicates: dict[str, list[str]]
    origin_unmapped: list[dict]


class MachO:
    def __init__(self, executable: str, app_root: str, lion_root: str | None):
        self.executable = real(executable)
        self.executable_dir = os.path.dirname(self.executable)
        self.app_root = real(app_root)
        self.lion_root = real(lion_root) if lion_root else None

    @lru_cache(maxsize=None)
    def load_info(self, path: str) -> tuple[tuple[tuple[str, str], ...], tuple[str, ...]]:
        p = run("otool", "-arch", ARCH, "-l", path)
        if p.returncode != 0:
            p = run("otool", "-l", path)
        deps: list[tuple[str, str]] = []
        rpaths: list[str] = []
        current_cmd: str | None = None

        for line in p.stdout.splitlines():
            m = LOAD_CMD_RE.match(line)
            if m:
                current_cmd = m.group(1)
                continue

            if current_cmd in LOAD_COMMANDS:
                n = NAME_RE.match(line)
                if n:
                    deps.append((current_cmd, n.group(1)))
                    current_cmd = None
                    continue

            if current_cmd == "LC_RPATH":
                r = PATH_RE.match(line)
                if r:
                    rpaths.append(r.group(1))
                    current_cmd = None

        return tuple(deps), tuple(rpaths)

    def _expand_special(self, value: str, loader: str) -> str:
        if value.startswith("@executable_path/"):
            return os.path.join(self.executable_dir, value[len("@executable_path/"):])
        if value == "@executable_path":
            return self.executable_dir
        if value.startswith("@loader_path/"):
            return os.path.join(os.path.dirname(loader), value[len("@loader_path/"):])
        if value == "@loader_path":
            return os.path.dirname(loader)
        return value

    def resolve(self, install_name: str, loader: str, sysroot: str | None = None) -> str | None:
        if install_name.startswith("@executable_path") or install_name.startswith("@loader_path"):
            candidate = real(self._expand_special(install_name, loader))
            return candidate if os.path.exists(candidate) else None

        if install_name.startswith("@rpath/"):
            _, rpaths = self.load_info(loader)
            suffix = install_name[len("@rpath/"):]
            for rp in rpaths:
                expanded = self._expand_special(rp, loader)
                candidate = real(os.path.join(expanded, suffix))
                if os.path.exists(candidate):
                    return candidate
            return None

        if install_name.startswith("/"):
            if sysroot:
                rooted = real(os.path.join(sysroot, install_name.lstrip("/")))
                if os.path.exists(rooted):
                    return rooted
            return real(install_name) if os.path.exists(install_name) else None

        candidate = real(os.path.join(os.path.dirname(loader), install_name))
        return candidate if os.path.exists(candidate) else None

    @lru_cache(maxsize=None)
    def exports_direct(self, path: str) -> frozenset[str]:
        p = run("nm", "-arch", ARCH, "-gjU", path)
        if p.returncode != 0:
            p = run("nm", "-gjU", path)
        return frozenset(x.strip() for x in p.stdout.splitlines() if x.strip())

    @lru_cache(maxsize=None)
    def undefined_by_origin(self, path: str) -> tuple[tuple[str, str], ...]:
        p = run("nm", "-arch", ARCH, "-m", path)
        if p.returncode != 0:
            p = run("nm", "-m", path)
        out: list[tuple[str, str]] = []
        for line in p.stdout.splitlines():
            m = UNDEF_RE.search(line)
            if m:
                out.append((m.group(1), m.group(2)))
        return tuple(out)

    def exports_with_reexports(
        self,
        path: str,
        *,
        sysroot: str | None = None,
        _seen: set[str] | None = None,
    ) -> set[str]:
        path = real(path)
        seen = set() if _seen is None else _seen
        if path in seen:
            return set()
        seen.add(path)

        result = set(self.exports_direct(path))
        deps, _ = self.load_info(path)
        for cmd, name in deps:
            if cmd != "LC_REEXPORT_DYLIB":
                continue
            dep = self.resolve(name, path, sysroot=sysroot)
            if dep and is_macho(dep):
                result.update(self.exports_with_reexports(dep, sysroot=sysroot, _seen=seen))
        return result

    def image(self, path: str) -> Image:
        raw_deps, rpaths = self.load_info(path)
        deps = [Dep(cmd, name, self.resolve(name, path)) for cmd, name in raw_deps]
        return Image(path=path, deps=deps, rpaths=list(rpaths))


def aliases_for_install_name(name: str) -> set[str]:
    aliases: set[str] = set()
    base = os.path.basename(name)
    aliases.add(base)
    if base.endswith(".dylib"):
        aliases.add(base[:-6])
    if base.startswith("lib") and ".dylib" in base:
        aliases.add(base[3:].split(".dylib")[0])
    frameworks = FRAMEWORK_RE.findall(name)
    aliases.update(frameworks)
    return {a for a in aliases if a}


def classify(symbol: str) -> str:
    if symbol.startswith("_OBJC_CLASS_$_"):
        return "objc_class"
    if symbol.startswith("_OBJC_METACLASS_$_"):
        return "objc_metaclass"
    if symbol.startswith("_OBJC_IVAR_$_"):
        return "objc_ivar"
    if symbol.startswith("_k") or symbol.endswith("Notification") or symbol.endswith("Key") or symbol.endswith("Domain"):
        return "global_or_constant"
    if symbol.startswith("__Z") or symbol.startswith("_Z"):
        return "cxx"
    return "function_or_global"


def logical_family(path: str) -> str | None:
    fs = FRAMEWORK_RE.findall(path)
    if fs:
        return fs[-1]
    base = os.path.basename(path)
    if base.endswith(".dylib"):
        return base
    return None


def equivalent_lion_path(provider_install_name: str | None, provider_path: str | None, lion_root: str | None) -> str | None:
    if not lion_root:
        return None

    # Prefer the original absolute install name because app-local copies may
    # have been rewritten to @executable_path.
    candidates: list[str] = []
    if provider_install_name and provider_install_name.startswith("/"):
        candidates.append(os.path.join(lion_root, provider_install_name.lstrip("/")))

    if provider_path and provider_path.startswith("/System/"):
        candidates.append(os.path.join(lion_root, provider_path.lstrip("/")))

    for c in candidates:
        c = real(c)
        if os.path.isfile(c):
            return c
    return None


def audit(executable: str, app_root: str, lion_root: str | None) -> Audit:
    macho = MachO(executable, app_root, lion_root)

    q = deque([real(executable)])
    images: dict[str, Image] = {}
    unresolved: list[dict] = []

    while q:
        path = q.popleft()
        if path in images or not is_macho(path):
            continue
        img = macho.image(path)
        images[path] = img
        for dep in img.deps:
            if dep.resolved is None:
                unresolved.append(
                    {
                        "consumer": path,
                        "command": dep.command,
                        "install_name": dep.install_name,
                    }
                )
            elif dep.resolved not in images and is_macho(dep.resolved):
                q.append(dep.resolved)

    app_local = sorted(p for p in images if p == app_root or p.startswith(app_root + os.sep))

    # Build direct dependency origin alias map for each consumer.
    missing: list[Missing] = []
    origin_unmapped: list[dict] = []

    for consumer in app_local:
        img = images[consumer]
        by_alias: dict[str, list[Dep]] = defaultdict(list)
        for dep in img.deps:
            for alias in aliases_for_install_name(dep.install_name):
                by_alias[alias].append(dep)

        grouped_imports: dict[str, set[str]] = defaultdict(set)
        for symbol, origin in macho.undefined_by_origin(consumer):
            grouped_imports[origin].add(symbol)

        for origin, symbols in sorted(grouped_imports.items()):
            candidates = by_alias.get(origin, [])

            # A few nm labels use the framework leaf even when basename differs.
            if not candidates:
                for dep in img.deps:
                    if origin in aliases_for_install_name(dep.install_name):
                        candidates.append(dep)

            if not candidates:
                origin_unmapped.append(
                    {
                        "consumer": consumer,
                        "origin": origin,
                        "symbols": sorted(symbols),
                    }
                )
                continue

            # Normally there is exactly one provider for an ordinal label.
            dep = candidates[0]
            if not dep.resolved or not os.path.isfile(dep.resolved):
                for symbol in sorted(symbols):
                    missing.append(
                        Missing(
                            consumer=consumer,
                            origin=origin,
                            provider_install_name=dep.install_name,
                            provider_path=dep.resolved,
                            symbol=symbol,
                            kind=classify(symbol),
                        )
                    )
                continue

            have = macho.exports_with_reexports(dep.resolved)
            absent = sorted(symbols - have)
            if not absent:
                continue

            lion_provider = equivalent_lion_path(dep.install_name, dep.resolved, lion_root)
            lion_exports: set[str] | None = None
            if lion_provider:
                lion_exports = macho.exports_with_reexports(
                    lion_provider,
                    sysroot=lion_root,
                )

            for symbol in absent:
                missing.append(
                    Missing(
                        consumer=consumer,
                        origin=origin,
                        provider_install_name=dep.install_name,
                        provider_path=dep.resolved,
                        symbol=symbol,
                        kind=classify(symbol),
                        lion_provider_path=lion_provider,
                        present_in_lion=(symbol in lion_exports) if lion_exports is not None else None,
                    )
                )

    families: dict[str, set[str]] = defaultdict(set)
    for path in images:
        fam = logical_family(path)
        if fam:
            families[fam].add(path)
    duplicates = {k: sorted(v) for k, v in families.items() if len(v) > 1}

    return Audit(
        executable=real(executable),
        app_root=real(app_root),
        closure=sorted(images),
        app_local_closure=app_local,
        unresolved_libraries=unresolved,
        missing_symbols=missing,
        duplicates=duplicates,
        origin_unmapped=origin_unmapped,
    )


def print_report(a: Audit) -> None:
    print("=== RUNTIME CLOSURE SUMMARY ===")
    print(f"images_total={len(a.closure)}")
    print(f"images_app_local={len(a.app_local_closure)}")
    print(f"unresolved_libraries={len(a.unresolved_libraries)}")
    print(f"missing_symbols={len(a.missing_symbols)}")
    print(f"duplicate_families={len(a.duplicates)}")
    print(f"unmapped_origins={len(a.origin_unmapped)}")

    if a.unresolved_libraries:
        print("\n=== UNRESOLVED LIBRARIES ===")
        for x in a.unresolved_libraries:
            print(f"{x['consumer']}")
            print(f"  {x['command']}: {x['install_name']}")

    if a.missing_symbols:
        print("\n=== MISSING SYMBOLS BY CONSUMER / PROVIDER ===")
        groups: dict[tuple[str, str, str | None], list[Missing]] = defaultdict(list)
        for m in a.missing_symbols:
            groups[(m.consumer, m.origin, m.provider_path)].append(m)

        for (consumer, origin, provider), items in sorted(groups.items()):
            print(f"\n--- CONSUMER: {consumer}")
            print(f"    PROVIDER: {origin} -> {provider}")
            kinds: dict[str, list[Missing]] = defaultdict(list)
            for m in items:
                kinds[m.kind].append(m)
            for kind in sorted(kinds):
                print(f"    [{kind}]")
                for m in sorted(kinds[kind], key=lambda x: x.symbol):
                    lion = ""
                    if m.present_in_lion is True:
                        lion = "  [exists in Lion provider]"
                    elif m.present_in_lion is False:
                        lion = "  [NOT found in Lion provider]"
                    print(f"      {m.symbol}{lion}")

    if a.duplicates:
        print("\n=== DUPLICATE FRAMEWORK / DYLIB FAMILIES IN CLOSURE ===")
        for family, paths in sorted(a.duplicates.items()):
            print(f"{family}:")
            for p in paths:
                print(f"  {p}")

    if a.origin_unmapped:
        print("\n=== UNMAPPED TWO-LEVEL ORIGINS ===")
        for x in a.origin_unmapped:
            print(f"{x['consumer']}: from {x['origin']} ({len(x['symbols'])} symbols)")

    print("\n=== APP-LOCAL CLOSURE ===")
    for p in a.app_local_closure:
        print(p)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("executable", help="Main Mach-O executable, e.g. iChat.app/Contents/MacOS/iChat")
    ap.add_argument("--app-root", help="App bundle root. Defaults to inferred *.app root")
    ap.add_argument("--lion-root", help="Extracted Lion filesystem root, e.g. ~/Downloads/Lion/SystemRoot")
    ap.add_argument("--json", dest="json_path", help="Write machine-readable report")
    args = ap.parse_args()

    exe = real(args.executable)
    if not os.path.isfile(exe):
        print(f"error: executable not found: {exe}", file=sys.stderr)
        return 2

    if args.app_root:
        app_root = real(args.app_root)
    else:
        marker = ".app" + os.sep
        idx = exe.find(marker)
        if idx < 0:
            print("error: cannot infer app root; pass --app-root", file=sys.stderr)
            return 2
        app_root = exe[: idx + len(".app")]

    result = audit(exe, app_root, args.lion_root)
    print_report(result)

    if args.json_path:
        out = {
            **asdict(result),
            "missing_symbols": [asdict(x) for x in result.missing_symbols],
        }
        Path(args.json_path).write_text(
            json.dumps(out, indent=2, ensure_ascii=False),
            encoding="utf-8",
        )
        print(f"\nJSON: {args.json_path}")

    return 1 if result.missing_symbols or result.unresolved_libraries else 0


if __name__ == "__main__":
    raise SystemExit(main())

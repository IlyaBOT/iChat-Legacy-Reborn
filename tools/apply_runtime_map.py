#!/usr/bin/env python3
"""
Apply declarative install-name patches to app-local Mach-O files.

The JSON map intentionally names target globs explicitly. This avoids rewriting
helper executables/XPC services with @executable_path values that are only valid
for the main iChat process.

Python 3.14+, standard library only.
"""

from __future__ import annotations

import argparse
import glob
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path


def run(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, errors="replace")


def expand(value: str, vars: dict[str, str]) -> str:
    out = os.path.expandvars(os.path.expanduser(value))
    for k, v in vars.items():
        out = out.replace("${" + k + "}", v)
    return out


def is_macho(path: str) -> bool:
    if not os.path.isfile(path):
        return False
    return "Mach-O" in run("file", path).stdout


def deps(path: str) -> set[str]:
    p = run("otool", "-L", path)
    if p.returncode != 0:
        return set()
    result = set()
    for line in p.stdout.splitlines()[1:]:
        s = line.strip()
        if not s:
            continue
        result.add(s.split(" (compatibility version", 1)[0].strip())
    return result


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("map", help="JSON runtime map")
    ap.add_argument("--app", required=True)
    ap.add_argument("--lion-root", required=True)
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    app = os.path.realpath(os.path.expanduser(args.app))
    lion_root = os.path.realpath(os.path.expanduser(args.lion_root))
    vars = {"APP": app, "LION_ROOT": lion_root}
    data = json.loads(Path(args.map).read_text(encoding="utf-8"))

    changed = 0
    copied = 0

    print("=== COPY OPERATIONS ===")
    for op in data.get("copy", []):
        src = expand(op["source"], vars)
        dst = expand(op["destination"], vars)
        print(f"{src} -> {dst}")
        if args.dry_run:
            continue
        if not os.path.exists(src):
            print(f"ERROR: source missing: {src}", file=sys.stderr)
            return 2
        if os.path.isdir(src):
            if os.path.exists(dst):
                shutil.rmtree(dst)
            shutil.copytree(src, dst, symlinks=True)
        else:
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            shutil.copy2(src, dst)
        copied += 1

    print("\n=== INSTALL NAME PATCHES ===")
    for rule in data.get("patches", []):
        old_values = [expand(x, vars) for x in rule.get("from", [])]
        new = expand(rule["to"], vars)
        targets: set[str] = set()

        for pattern in rule.get("targets", []):
            full_pattern = expand(pattern, vars)
            targets.update(glob.glob(full_pattern, recursive=True))

        for path in sorted(targets):
            if not is_macho(path):
                continue
            current = deps(path)
            for old in old_values:
                if old not in current:
                    continue
                print(f"{path}\n  {old}\n  -> {new}")
                if not args.dry_run:
                    p = run("install_name_tool", "-change", old, new, path)
                    if p.returncode != 0:
                        print(p.stderr.rstrip(), file=sys.stderr)
                        return 3
                changed += 1

    print("\n=== ID PATCHES ===")
    for rule in data.get("ids", []):
        path = expand(rule["path"], vars)
        new_id = expand(rule["id"], vars)
        if not os.path.isfile(path):
            print(f"SKIP missing: {path}")
            continue
        print(f"{path}\n  id -> {new_id}")
        if not args.dry_run:
            p = run("install_name_tool", "-id", new_id, path)
            if p.returncode != 0:
                print(p.stderr.rstrip(), file=sys.stderr)
                return 4

    print(f"\nDONE copied={copied} patched={changed} dry_run={args.dry_run}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

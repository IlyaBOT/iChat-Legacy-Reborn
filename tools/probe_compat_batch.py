#!/usr/bin/env python3
"""
Batch probe all unresolved ABI providers from audit_runtime_closure.py.

Input: runtime audit JSON + extracted Lion filesystem root.
Output:
  * exact missing symbols grouped by provider;
  * actual Lion image that directly exports each symbol (following re-exports);
  * Mach-O symbol type/section;
  * ObjC class layout + ivars + method signatures;
  * CFString constant values when extract_cfstring_constants.py can resolve them;
  * whether the whole Lion provider can run against the current Snow Leopard
    dependency surfaces without additional symbol gaps.

This tool never modifies binaries.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import os
import re
import subprocess
import sys
from collections import defaultdict
from pathlib import Path
from typing import Any

ARCH="x86_64"
CLASS_PREFIX="_OBJC_CLASS_$_"
META_PREFIX="_OBJC_METACLASS_$_"

def run(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                          text=True, errors="replace")

def load_auditor():
    here=Path(__file__).resolve().parent
    path=here/"audit_runtime_closure.py"
    spec=importlib.util.spec_from_file_location("runtime_audit", path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot import {path}")
    mod=importlib.util.module_from_spec(spec)
    sys.modules[spec.name]=mod
    spec.loader.exec_module(mod)
    return mod

def nm_line(path: str, symbol: str) -> str | None:
    p=run("nm","-arch",ARCH,"-m",path)
    if p.returncode:
        p=run("nm","-m",path)
    for line in p.stdout.splitlines():
        if re.search(r"(?:^|\s)"+re.escape(symbol)+r"$", line):
            return line.strip()
    return None

def reexport_closure(macho, root: str, sysroot: str | None) -> list[str]:
    out=[]
    seen=set()
    def walk(path: str):
        path=os.path.realpath(path)
        if path in seen or not os.path.isfile(path):
            return
        seen.add(path)
        out.append(path)
        deps,_=macho.load_info(path)
        for cmd,name in deps:
            if cmd!="LC_REEXPORT_DYLIB":
                continue
            dep=macho.resolve(name,path,sysroot=sysroot)
            if dep:
                walk(dep)
    walk(root)
    return out

def direct_exporter(macho, root: str, symbol: str, sysroot: str | None) -> str | None:
    for path in reexport_closure(macho,root,sysroot):
        if symbol in macho.exports_direct(path):
            return path
    return None

def class_block(path: str, cls: str) -> str:
    p=run("otool","-arch",ARCH,"-ov",path)
    if p.returncode:
        p=run("otool","-ov",path)
    lines=p.stdout.splitlines()
    needle=CLASS_PREFIX+cls
    start=None
    for i,line in enumerate(lines):
        if needle in line and re.match(r"^[0-9a-fA-F]+\s+",line.strip()):
            start=i
            break
    if start is None:
        return "<class metadata not found>"
    end=min(len(lines),start+500)
    for j in range(start+1,min(len(lines),start+500)):
        s=lines[j].strip()
        if re.match(r"^[0-9a-fA-F]+\s+0x[0-9a-fA-F]+\s+_OBJC_(?:CLASS|METACLASS)_\$_",s):
            end=j
            break
    block=lines[start:end]

    superclass=None
    instance_start=None
    instance_size=None
    ivars=[]
    methods=[]
    state=None
    pending_method={}
    pending_ivar={}

    for line in block:
        s=line.strip()
        if s.startswith("superclass "):
            superclass=s
        elif s.startswith("instanceStart "):
            instance_start=s.split()[-1]
        elif s.startswith("instanceSize "):
            instance_size=s.split()[-1]
        elif s.startswith("ivars "):
            state="ivars"
        elif s.startswith("baseMethods "):
            state="methods"
        elif s.startswith("baseProperties ") or s.startswith("weakIvarLayout "):
            if state=="ivars":
                state=None
        elif state=="ivars":
            if s.startswith("offset "):
                if pending_ivar:
                    ivars.append(pending_ivar); pending_ivar={}
                pending_ivar["offset"]=s.split()[-1]
            elif s.startswith("name "):
                pending_ivar["name"]=s.split("name",1)[1].strip()
            elif s.startswith("type "):
                pending_ivar["type"]=s.split("type",1)[1].strip()
            elif s.startswith("size "):
                pending_ivar["size"]=s.split()[-1]
        elif state=="methods":
            if s.startswith("name "):
                if pending_method:
                    methods.append(pending_method); pending_method={}
                pending_method["name"]=s.split("name",1)[1].strip()
            elif s.startswith("types "):
                pending_method["types"]=s.split("types",1)[1].strip()

    if pending_ivar: ivars.append(pending_ivar)
    if pending_method: methods.append(pending_method)

    out=[f"class {cls}"]
    if superclass: out.append(f"  {superclass}")
    if instance_start is not None: out.append(f"  instanceStart {instance_start}")
    if instance_size is not None: out.append(f"  instanceSize {instance_size}")
    if ivars:
        out.append("  ivars:")
        for x in ivars:
            out.append("    "+", ".join(f"{k}={v}" for k,v in x.items()))
    if methods:
        out.append("  methods:")
        seen=set()
        for x in methods:
            key=(x.get("name"),x.get("types"))
            if key in seen: continue
            seen.add(key)
            out.append(f"    {x.get('name','?')} :: {x.get('types','?')}")
    return "\n".join(out)

def dependency_compat(macho, lion_provider: str) -> dict[str,Any]:
    deps,_=macho.load_info(lion_provider)
    by_alias=defaultdict(list)
    for cmd,name in deps:
        for alias in macho_aliases(name):
            by_alias[alias].append((cmd,name))

    grouped=defaultdict(set)
    for sym,origin in macho.undefined_by_origin(lion_provider):
        grouped[origin].add(sym)

    problems=[]
    total_needed=0
    total_missing=0
    unresolved=0
    for origin,symbols in sorted(grouped.items()):
        total_needed += len(symbols)
        candidates=by_alias.get(origin,[])
        if not candidates:
            problems.append({"origin":origin,"status":"unmapped","missing":sorted(symbols)})
            total_missing += len(symbols)
            continue
        _,name=candidates[0]
        snow=macho.resolve(name,lion_provider,sysroot=None)
        if not snow or not os.path.isfile(snow):
            problems.append({"origin":origin,"install_name":name,"status":"provider_missing_on_snow","missing":sorted(symbols)})
            total_missing += len(symbols); unresolved += 1
            continue
        have=macho.exports_with_reexports(snow)
        miss=sorted(symbols-have)
        if miss:
            problems.append({"origin":origin,"install_name":name,"snow_provider":snow,"status":"symbol_gaps","missing":miss})
            total_missing += len(miss)
    return {
        "needed":total_needed,
        "missing":total_missing,
        "unresolved_dependencies":unresolved,
        "bundle_candidate": total_missing==0 and unresolved==0,
        "problems":problems,
    }

def macho_aliases(name: str) -> set[str]:
    base=os.path.basename(name)
    out={base}
    fs=re.findall(r"/([^/]+)\.framework(?:/|$)",name)
    if fs: out.add(fs[-1])
    if base.endswith(".dylib"):
        out.add(base[:-6])
        m=re.match(r"^(lib[^.]+)(?:\..*)?\.dylib$",base)
        if m: out.add(m.group(1))
    return {x for x in out if x}

def cfstring_probe(extractor: Path, image: str, symbols: list[str]) -> str:
    if not extractor.is_file() or not symbols:
        return ""
    names=[]
    for s in symbols:
        names.append(s[1:] if s.startswith("_") else s)
    p=run(sys.executable,str(extractor),image,*names)
    return (p.stdout+p.stderr).strip()

def main() -> int:
    ap=argparse.ArgumentParser()
    ap.add_argument("audit_json")
    ap.add_argument("--lion-root",required=True)
    ap.add_argument("--output")
    args=ap.parse_args()

    data=json.loads(Path(args.audit_json).read_text(encoding="utf-8"))
    lion_root=os.path.realpath(os.path.expanduser(args.lion_root))
    app=data["app_root"]
    exe=data["executable"]

    mod=load_auditor()
    macho=mod.MachO(exe,app,lion_root)
    extractor=Path(__file__).resolve().parent/"extract_cfstring_constants.py"

    groups=defaultdict(list)
    for m in data.get("missing_symbols",[]):
        key=(m.get("origin"),m.get("provider_path"),m.get("provider_install_name"),m.get("lion_provider_path"))
        groups[key].append(m)

    out=[]
    emit=out.append
    emit("=== BATCH COMPAT PROBE ===")
    emit(f"providers={len(groups)} missing_symbols={sum(len(v) for v in groups.values())}")

    for (origin,provider_path,provider_install,lion_provider),items in sorted(groups.items(),key=lambda kv:str(kv[0])):
        emit("\n"+"="*78)
        emit(f"PROVIDER {origin}")
        emit(f"  snow: {provider_path}")
        emit(f"  install-name: {provider_install}")
        emit(f"  lion umbrella/provider: {lion_provider}")

        if not lion_provider or not os.path.isfile(lion_provider):
            emit("  ERROR: Lion provider unavailable")
            continue

        symbols=sorted({m["symbol"] for m in items})
        emit("  missing:")
        for s in symbols:
            exporter=direct_exporter(macho,lion_provider,s,lion_root)
            line=nm_line(exporter,s) if exporter else None
            emit(f"    {s}")
            emit(f"      exporter: {exporter}")
            if line: emit(f"      nm: {line}")

        emit("\n  === UMBRELLA LION PROVIDER -> SNOW DEPENDENCY AUDIT ===")
        compat=dependency_compat(macho,lion_provider)
        emit(f"  needed={compat['needed']} missing={compat['missing']} unresolved_deps={compat['unresolved_dependencies']} bundle_candidate={compat['bundle_candidate']}")
        for problem in compat["problems"]:
            emit(f"    {problem['origin']}: {problem['status']} missing={len(problem['missing'])}")
            for s in problem["missing"][:80]:
                emit(f"      {s}")
            if len(problem["missing"])>80:
                emit(f"      ... {len(problem['missing'])-80} more")

        exporters=sorted({direct_exporter(macho,lion_provider,s,lion_root) for s in symbols})
        exporters=[x for x in exporters if x]
        if exporters:
            emit("\n  === DIRECT EXPORTER -> SNOW DEPENDENCY AUDIT ===")
            for exporter in exporters:
                excompat=dependency_compat(macho,exporter)
                emit(f"  -- {exporter}")
                emit(f"     needed={excompat['needed']} missing={excompat['missing']} unresolved_deps={excompat['unresolved_dependencies']} bundle_candidate={excompat['bundle_candidate']}")
                for problem in excompat["problems"]:
                    emit(f"       {problem['origin']}: {problem['status']} missing={len(problem['missing'])}")
                    for s in problem["missing"][:40]:
                        emit(f"         {s}")
                    if len(problem["missing"])>40:
                        emit(f"         ... {len(problem['missing'])-40} more")

        classes=sorted({s[len(CLASS_PREFIX):] for s in symbols if s.startswith(CLASS_PREFIX)})
        if classes:
            emit("\n  === OBJC CLASS METADATA ===")
            for cls in classes:
                exporter=direct_exporter(macho,lion_provider,CLASS_PREFIX+cls,lion_root) or lion_provider
                emit(class_block(exporter,cls))

        constants=[s for s in symbols if (
            s.startswith("_k") or s.startswith("__k") or
            s.endswith("Notification") or s.endswith("Key") or s.endswith("Domain") or
            "Encodings" in s
        )]
        if constants:
            emit("\n  === CFSTRING/POINTER CONSTANT PROBE ===")
            by_exporter=defaultdict(list)
            for s in constants:
                ex=direct_exporter(macho,lion_provider,s,lion_root)
                if ex: by_exporter[ex].append(s)
            for image,syms in sorted(by_exporter.items()):
                emit(f"  -- {image}")
                text=cfstring_probe(extractor, image, syms)
                emit(text if text else "  <no extractor output>")

    report="\n".join(out)+"\n"
    if args.output:
        Path(args.output).write_text(report,encoding="utf-8")
    print(report,end="")
    return 0

if __name__=="__main__":
    raise SystemExit(main())

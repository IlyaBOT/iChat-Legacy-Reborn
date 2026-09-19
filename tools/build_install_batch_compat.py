#!/usr/bin/env python3
"""
Build, install and audit the Milestone-1 batch compatibility pack.

One command:
  python3.14 tools/build_install_batch_compat.py \
      --app ~/Desktop/iChat6-Test/iChat.app \
      --lion-root ~/Downloads/Lion/SystemRoot

Requires gcc-4.2, make, otool, nm, install_name_tool.
"""

from __future__ import annotations
import argparse
import os
import shutil
import subprocess
import sys
from pathlib import Path

def run(cmd, *, cwd=None, capture=False):
    print("+"," ".join(str(x) for x in cmd))
    if capture:
        return subprocess.run(cmd,cwd=cwd,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,errors="replace")
    p=subprocess.run(cmd,cwd=cwd)
    if p.returncode:
        raise SystemExit(p.returncode)
    return p

def main() -> int:
    ap=argparse.ArgumentParser()
    ap.add_argument("--app",required=True)
    ap.add_argument("--lion-root",required=True)
    ap.add_argument("--repo-root",default=None)
    ap.add_argument("--cc",default="gcc-4.2")
    ap.add_argument("--report-dir",default=None)
    args=ap.parse_args()

    script=Path(__file__).resolve()
    repo=Path(args.repo_root).resolve() if args.repo_root else script.parent.parent
    app=Path(os.path.expanduser(args.app)).resolve()
    lion=Path(os.path.expanduser(args.lion_root)).resolve()
    report_dir=Path(os.path.expanduser(args.report_dir)).resolve() if args.report_dir else app.parent
    report_dir.mkdir(parents=True,exist_ok=True)

    if not (app/"Contents/MacOS/iChat").is_file():
        raise SystemExit(f"iChat executable not found in {app}")

    batch=repo/"project/BatchCompat"
    build=batch/"build"
    generated=build/"generated"

    run(["make","clean"],cwd=str(batch))
    run([sys.executable,str(repo/"tools/generate_batch_constants.py"),"--lion-root",str(lion),"--output-dir",str(generated)])
    run(["make",f"CC={args.cc}",f"GENERATED_DIR={generated}",f"BUILD_DIR={build}"],cwd=str(batch))

    fw=app/"Contents/Frameworks"
    fw.mkdir(parents=True,exist_ok=True)
    names=["AppKitCompat.dylib","CoreServicesCompat.dylib","QuartzCompat.dylib","ScreenSharingCompat.dylib","LibSystemCompat.dylib"]
    for name in names:
        src=build/name
        dst=fw/name
        if not src.is_file():
            raise SystemExit(f"build output missing: {src}")
        shutil.copy2(src,dst)
        print(f"installed {dst}")

    run([
        sys.executable,str(repo/"tools/apply_runtime_map.py"),
        str(repo/"patches/milestone1-runtime-map.json"),
        "--app",str(app),"--lion-root",str(lion)
    ])

    audit_txt=report_dir/"iChat6-runtime-audit-batch.txt"
    audit_json=report_dir/"iChat6-runtime-audit-batch.json"
    p=run([
        sys.executable,str(repo/"tools/audit_runtime_closure.py"),
        str(app/"Contents/MacOS/iChat"),
        "--app-root",str(app),
        "--lion-root",str(lion),
        "--json",str(audit_json)
    ],capture=True)
    audit_txt.write_text(p.stdout,encoding="utf-8")
    print(p.stdout,end="")
    print(f"audit text: {audit_txt}")
    print(f"audit json: {audit_json}")

    # The auditor returns 1 while any static gaps remain; that is report data,
    # not a build/install failure.
    return 0

if __name__=="__main__":
    raise SystemExit(main())

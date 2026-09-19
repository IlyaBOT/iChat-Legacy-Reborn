#!/usr/bin/env python3
"""
Generate exact compatibility string constants from the local Lion binaries.

No Apple binary or extracted framework content is written to the repository.
Only small generated Objective-C/C source files are emitted into the requested
build directory.
"""

from __future__ import annotations
import argparse
import importlib.util
import os
from pathlib import Path

def load_extractor():
    here=Path(__file__).resolve().parent
    path=here/"extract_cfstring_constants.py"
    spec=importlib.util.spec_from_file_location("cfextract",path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot import {path}")
    mod=importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod

def objc_quote(s: str) -> str:
    return s.replace("\\","\\\\").replace('"','\\"').replace("\n","\\n").replace("\r","\\r")

def extract_exact(mod, path: str, macho_symbol: str) -> str:
    blob=Path(path).read_bytes()
    data=mod.select_x86_64(blob)
    sections,symtab=mod.parse_macho64(data)
    symbols=mod.load_symbols(data,symtab)
    if macho_symbol not in symbols:
        raise RuntimeError(f"{macho_symbol}: symbol not found in {path}")
    value=symbols[macho_symbol][0]
    text,how=mod.resolve_constant(data,sections,value)
    if text is None:
        raise RuntimeError(f"{macho_symbol}: unable to resolve CFString in {path}")
    print(f"{macho_symbol} = {text!r} [{how}]")
    return text

def main() -> int:
    ap=argparse.ArgumentParser()
    ap.add_argument("--lion-root",required=True)
    ap.add_argument("--output-dir",required=True)
    args=ap.parse_args()

    root=os.path.realpath(os.path.expanduser(args.lion_root))
    out=Path(os.path.expanduser(args.output_dir))
    out.mkdir(parents=True,exist_ok=True)
    ex=load_extractor()

    appkit=os.path.join(root,"System/Library/Frameworks/AppKit.framework/Versions/C/AppKit")
    launchservices=os.path.join(root,"System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/LaunchServices")
    imagekit=os.path.join(root,"System/Library/Frameworks/Quartz.framework/Versions/A/Frameworks/ImageKit.framework/Versions/A/ImageKit")
    screensharing=os.path.join(root,"System/Library/PrivateFrameworks/ScreenSharing.framework/Versions/A/ScreenSharing")

    appkit_syms=[
        ("_NSWindowDidChangeBackingPropertiesNotification","NSWindowDidChangeBackingPropertiesNotification"),
        ("_NSWindowDidEnterFullScreenNotification","NSWindowDidEnterFullScreenNotification"),
        ("_NSWindowDidExitFullScreenNotification","NSWindowDidExitFullScreenNotification"),
        ("_NSWindowWillEnterFullScreenNotification","NSWindowWillEnterFullScreenNotification"),
        ("_NSWindowWillExitFullScreenNotification","NSWindowWillExitFullScreenNotification"),
    ]

    lines=['#import <Foundation/Foundation.h>']
    for macho,cident in appkit_syms:
        value=extract_exact(ex,appkit,macho)
        lines.append(f'NSString * const {cident} = @"{objc_quote(value)}";')
    (out/"AppKitConstants.m").write_text("\n".join(lines)+"\n",encoding="utf-8")

    value=extract_exact(ex,launchservices,"__kLSApplicationWasTerminatedByTALKey")
    (out/"CoreServicesConstants.c").write_text(
        '#include <CoreFoundation/CoreFoundation.h>\n'
        f'const CFStringRef _kLSApplicationWasTerminatedByTALKey = CFSTR("{objc_quote(value)}");\n',
        encoding="utf-8")

    value=extract_exact(ex,imagekit,"_IKPictureTakerFacesAlbumIdentifierKey")
    (out/"QuartzConstants.m").write_text(
        '#import <Foundation/Foundation.h>\n'
        f'NSString * const IKPictureTakerFacesAlbumIdentifierKey = @"{objc_quote(value)}";\n',
        encoding="utf-8")

    value=extract_exact(ex,screensharing,"_kSSPreauthorized")
    (out/"ScreenSharingConstants.m").write_text(
        '#import <Foundation/Foundation.h>\n'
        f'NSString * const kSSPreauthorized = @"{objc_quote(value)}";\n',
        encoding="utf-8")

    print(f"generated constants in {out}")
    return 0

if __name__=="__main__":
    raise SystemExit(main())

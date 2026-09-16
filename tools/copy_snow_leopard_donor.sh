#!/bin/bash
set -e
ROOT="${1:-vendor/snow-leopard}"
mkdir -p "$ROOT/Applications" "$ROOT/System/Library/Frameworks"
ditto /Applications/iChat.app "$ROOT/Applications/iChat.app"
ditto /System/Library/Frameworks/IMCore.framework "$ROOT/System/Library/Frameworks/IMCore.framework"
ditto /System/Library/Frameworks/InstantMessage.framework "$ROOT/System/Library/Frameworks/InstantMessage.framework"
echo "Snow Leopard donor copied to $ROOT"

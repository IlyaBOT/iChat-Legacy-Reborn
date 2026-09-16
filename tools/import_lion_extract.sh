#!/bin/bash
set -e
SRC="$1"
DST="${2:-vendor/lion}"
if [ -z "$SRC" ] || [ ! -d "$SRC" ]; then echo "usage: $0 /path/to/LionExtract/PackagesExpanded [destination]" >&2; exit 2; fi
rm -rf "$DST"
mkdir -p "$DST"
for payload in "$SRC"/*/Payload; do
  [ -d "$payload" ] || continue
  ditto "$payload" "$DST"
done
echo "Lion donor merged into $DST"

#!/bin/bash
set -u

APP="${1:-$HOME/Desktop/iChat6-Test/iChat.app}"
OUTDIR="${2:-$HOME/Desktop/iChat6-Test/runtime-diagnostics}"
BIN="$APP/Contents/MacOS/iChat"

mkdir -p "$OUTDIR"

STAMP=$(date '+%Y%m%d-%H%M%S')
GDBLOG="$OUTDIR/iChat-gdb-$STAMP.txt"
NORMALLOG="$OUTDIR/iChat-normal-$STAMP.txt"
DUPLOG="$OUTDIR/iChat-duplicates-$STAMP.txt"
CRASHLIST="$OUTDIR/iChat-crashreports-$STAMP.txt"
GDBCMD="$OUTDIR/iChat-gdb-$STAMP.cmd"

if [ ! -x "$BIN" ]; then
    echo "ERROR: iChat binary not executable: $BIN"
    exit 2
fi

echo "=== RUNTIME DIAGNOSTICS ==="
echo "APP=$APP"
echo "OUTDIR=$OUTDIR"
echo

echo "=== STATIC ACTIVE COMPAT DEPENDENCIES ==="
otool -L "$BIN" | grep -E 'Compat|IMCore|InstantMessage|DataDetectorsCore|CoreMedia|AppKit|Foundation|Quartz|ScreenSharing|CoreServices|libSystem' || true
echo

echo "=== DUPLICATE-CLASS NORMAL LAUNCH ==="
OBJC_PRINT_DUPLICATE_CLASSES=YES NSUnbufferedIO=YES "$BIN" >"$NORMALLOG" 2>&1 &
PID=$!
sleep 3
if kill -0 "$PID" 2>/dev/null; then
    echo "normal launch still alive after 3s: pid=$PID"
    kill "$PID" 2>/dev/null || true
    wait "$PID" 2>/dev/null || true
else
    wait "$PID" 2>/dev/null || true
fi
grep -E 'implemented in both|Class .* is implemented|abort|Abort|Exception|exception|Terminating|assert|Assertion|fatal|Fatal' "$NORMALLOG" >"$DUPLOG" || true
cat "$DUPLOG"
echo

GDB=""
for CAND in /usr/bin/gdb /Developer/usr/bin/gdb "$(command -v gdb 2>/dev/null || true)"; do
    if [ -n "$CAND" ] && [ -x "$CAND" ]; then
        GDB="$CAND"
        break
    fi
done

if [ -n "$GDB" ]; then
    cat >"$GDBCMD" <<'EOF'
set pagination off
set confirm off
set print pretty on
set env NSUnbufferedIO YES
set env OBJC_PRINT_DUPLICATE_CLASSES YES
set env DYLD_PRINT_LIBRARIES 0
handle SIGPIPE nostop noprint pass
handle SIGABRT stop print nopass
handle SIGTRAP stop print nopass
break abort
commands
silent
printf "\n===== BREAKPOINT: abort() =====\n"
bt
continue
end
break objc_exception_throw
commands
silent
printf "\n===== BREAKPOINT: objc_exception_throw =====\n"
bt
continue
end
run
printf "\n===== STOPPED: ALL THREADS =====\n"
thread apply all bt full
printf "\n===== REGISTERS =====\n"
info registers
printf "\n===== SHARED LIBRARIES =====\n"
info sharedlibrary
quit
EOF

    echo "=== GDB RUN ==="
    echo "GDB=$GDB"
    "$GDB" -q -batch -x "$GDBCMD" --args "$BIN" >"$GDBLOG" 2>&1 || true
    echo "=== GDB SIGNAL / TOP FRAMES ==="
    grep -E -A35 -B5 'BREAKPOINT:|Program received signal|STOPPED: ALL THREADS|SIGABRT|SIGTRAP|abort\(\)|objc_exception_throw' "$GDBLOG" | tail -220 || true
else
    echo "WARNING: gdb not found; skipping debugger backtrace"
fi

echo
echo "=== RECENT CRASH REPORTS ==="
: >"$CRASHLIST"
for D in "$HOME/Library/Logs/DiagnosticReports" "$HOME/Library/Logs/CrashReporter" "/Library/Logs/DiagnosticReports"; do
    [ -d "$D" ] || continue
    ls -1t "$D"/iChat*.crash 2>/dev/null | head -5 >>"$CRASHLIST" || true
done
awk '!seen[$0]++' "$CRASHLIST" >"$CRASHLIST.tmp" 2>/dev/null || true
mv "$CRASHLIST.tmp" "$CRASHLIST" 2>/dev/null || true
cat "$CRASHLIST"

LATEST=$(head -1 "$CRASHLIST" 2>/dev/null || true)
if [ -n "$LATEST" ] && [ -f "$LATEST" ]; then
    cp "$LATEST" "$OUTDIR/$(basename "$LATEST")" 2>/dev/null || true
    echo
    echo "=== CRASH REPORT HEAD ==="
    sed -n '1,140p' "$LATEST"
fi

echo
echo "=== OUTPUT FILES ==="
echo "$NORMALLOG"
echo "$DUPLOG"
[ -n "$GDB" ] && echo "$GDBLOG"
echo "$CRASHLIST"

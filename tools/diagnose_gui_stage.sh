#!/bin/bash
set -u

APP="${1:-$HOME/Desktop/iChat6-Test/iChat.app}"
OUTDIR="${2:-$HOME/Desktop/iChat6-Test/gui-diagnostics}"
BIN="$APP/Contents/MacOS/iChat"
STAMP=$(date '+%Y%m%d-%H%M%S')
REPORT="$OUTDIR/iChat-gui-$STAMP.txt"
SAMPLE="$OUTDIR/iChat-sample-$STAMP.txt"

mkdir -p "$OUTDIR"
exec > >(tee "$REPORT") 2>&1

echo "=== GUI STAGE DIAGNOSTICS ==="
echo "date=$(date)"
echo "user=$(id -un)"
echo "uid=$(id -u)"
echo "console_user=$(/usr/bin/stat -f '%Su' /dev/console 2>/dev/null || echo unknown)"
echo "ssh_connection=${SSH_CONNECTION:-<none>}"
echo "app=$APP"
echo

echo "=== AQUA / WINDOWSERVER ==="
ps axww | grep -E '[W]indowServer|[D]ock.app/Contents/MacOS/Dock|[S]ystemUIServer.app/Contents/MacOS/SystemUIServer|[F]inder.app/Contents/MacOS/Finder' || true
echo

echo "=== INFO.PLIST GUI FLAGS ==="
for K in CFBundleIdentifier CFBundleExecutable CFBundlePackageType NSPrincipalClass LSUIElement LSBackgroundOnly; do
    V=$(/usr/bin/defaults read "$APP/Contents/Info" "$K" 2>/dev/null || true)
    echo "$K=${V:-<unset>}"
done
echo

echo "=== PREVIOUS ICHAT PROCESSES ==="
ps axww | grep -F "$BIN" | grep -v grep || true
OLDPIDS=$(ps axww -o pid= -o command= | awk -v b="$BIN" 'index($0,b){print $1}')
if [ -n "$OLDPIDS" ]; then
    echo "$OLDPIDS" | xargs kill 2>/dev/null || true
    sleep 1
fi

echo
echo "=== LAUNCHSERVICES LAUNCH ==="
/usr/bin/open "$APP"
OPENRC=$?
echo "open_rc=$OPENRC"
sleep 5

PID=$(ps axww -o pid= -o command= | awk -v b="$BIN" 'index($0,b){print $1; exit}')
if [ -z "$PID" ]; then
    echo "RESULT=no_iChat_process_after_5s"
    echo
    echo "=== RECENT CRASH REPORTS ==="
    for D in "$HOME/Library/Logs/DiagnosticReports" "$HOME/Library/Logs/CrashReporter"; do
        [ -d "$D" ] || continue
        ls -lt "$D"/iChat*.crash 2>/dev/null | head -3 || true
    done
    echo
    echo "REPORT=$REPORT"
    exit 0
fi

echo "PID=$PID"
ps -p "$PID" -o pid,ppid,stat,etime,command
echo

echo "=== SYSTEM EVENTS PROCESS STATE ==="
/usr/bin/osascript <<'EOF' 2>&1 || true
tell application "System Events"
    if exists process "iChat" then
        tell process "iChat"
            set wc to count of windows
            set vis to visible
            set fm to frontmost
            return "exists=true windows=" & wc & " visible=" & vis & " frontmost=" & fm
        end tell
    else
        return "exists=false"
    end if
end tell
EOF
echo

echo "=== TRY ACTIVATE VIA APPLE EVENT ==="
/usr/bin/osascript -e 'tell application "iChat" to activate' 2>&1 || true
sleep 2
/usr/bin/osascript <<'EOF' 2>&1 || true
tell application "System Events"
    if exists process "iChat" then
        tell process "iChat"
            return "after_activate windows=" & (count of windows) & " visible=" & visible & " frontmost=" & frontmost
        end tell
    else
        return "after_activate exists=false"
    end if
end tell
EOF
echo

echo "=== PROCESS FILES / CONNECTIONS SUMMARY ==="
if command -v lsof >/dev/null 2>&1; then
    lsof -p "$PID" 2>/dev/null | grep -E 'iChat|Framework|Library/Preferences|Library/Caches|Library/Application Support' | tail -120 || true
fi
echo

echo "=== SAMPLE MAIN PROCESS ==="
if command -v sample >/dev/null 2>&1; then
    sample "$PID" 3 1 -file "$SAMPLE" >/dev/null 2>&1 || sample "$PID" 3 -file "$SAMPLE" >/dev/null 2>&1 || true
    if [ -f "$SAMPLE" ]; then
        grep -E -A35 -B5 'Call graph:|Thread_0|DispatchQueue|NSApplicationMain|CFRunLoop|mach_msg|_RegisterApplication|GetCurrentProcess|HIServices|abort|objc_exception' "$SAMPLE" | head -260 || true
    else
        echo "sample_failed"
    fi
else
    echo "sample_not_found"
fi
echo

echo "=== RECENT ICHAT CRASH FILE MTIMES ==="
for D in "$HOME/Library/Logs/DiagnosticReports" "$HOME/Library/Logs/CrashReporter"; do
    [ -d "$D" ] || continue
    ls -lt "$D"/iChat*.crash 2>/dev/null | head -3 || true
done
echo

echo "=== RESULT ==="
if kill -0 "$PID" 2>/dev/null; then
    echo "process_alive=true"
else
    echo "process_alive=false"
fi
echo "REPORT=$REPORT"
echo "SAMPLE=$SAMPLE"

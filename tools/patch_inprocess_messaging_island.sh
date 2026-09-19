#!/bin/bash
set -u

APP="${1:-$HOME/Desktop/iChat6-Test/iChat.app}"
FW="$APP/Contents/Frameworks"
BIN="$APP/Contents/MacOS/iChat"

LOCAL_CORE="@executable_path/../Frameworks/IMCore.framework/Versions/A/IMCore"
LOCAL_FOUND="@executable_path/../Frameworks/IMCore.framework/Versions/A/Frameworks/IMFoundation.framework/Versions/A/IMFoundation"
LOCAL_IM="@executable_path/../Frameworks/InstantMessage.framework/Versions/A/InstantMessage"
LOCAL_IMRF="@executable_path/../Frameworks/InstantMessage.framework/Versions/A/Frameworks/IMRenderingFoundation.framework/Versions/A/IMRenderingFoundation"
LOCAL_DDC="@executable_path/../Frameworks/DataDetectorsCore.framework/Versions/A/DataDetectorsCore"
LOCAL_PN="@executable_path/../Frameworks/PhoneNumbers.framework/Versions/A/PhoneNumbers"

patch_one()
{
    FILE="$1"
    OLD="$2"
    NEW="$3"
    [ -f "$FILE" ] || return 0
    if otool -L "$FILE" 2>/dev/null | awk '{print $1}' | grep -Fqx "$OLD"; then
        install_name_tool -change "$OLD" "$NEW" "$FILE"
        echo "PATCHED: $FILE"
        echo "    $OLD"
        echo " -> $NEW"
    fi
}

patch_module()
{
    FILE="$1"

    patch_one "$FILE" "/System/Library/PrivateFrameworks/IMCore.framework/Versions/A/IMCore" "$LOCAL_CORE"
    patch_one "$FILE" "/System/Library/Frameworks/IMCore.framework/Versions/A/IMCore" "$LOCAL_CORE"

    patch_one "$FILE" "/System/Library/PrivateFrameworks/IMCore.framework/Versions/A/Frameworks/IMFoundation.framework/Versions/A/IMFoundation" "$LOCAL_FOUND"
    patch_one "$FILE" "/System/Library/Frameworks/IMCore.framework/Versions/A/Frameworks/IMFoundation.framework/Versions/A/IMFoundation" "$LOCAL_FOUND"
    patch_one "$FILE" "/System/Library/Frameworks/IMCore.framework/Frameworks/IMFoundation.framework/Versions/A/IMFoundation" "$LOCAL_FOUND"

    patch_one "$FILE" "/System/Library/Frameworks/InstantMessage.framework/Versions/A/InstantMessage" "$LOCAL_IM"

    patch_one "$FILE" "/System/Library/Frameworks/InstantMessage.framework/Versions/A/Frameworks/IMRenderingFoundation.framework/Versions/A/IMRenderingFoundation" "$LOCAL_IMRF"
    patch_one "$FILE" "/System/Library/Frameworks/InstantMessage.framework/Frameworks/IMRenderingFoundation.framework/Versions/A/IMRenderingFoundation" "$LOCAL_IMRF"

    patch_one "$FILE" "/System/Library/PrivateFrameworks/DataDetectorsCore.framework/Versions/A/DataDetectorsCore" "$LOCAL_DDC"
    patch_one "$FILE" "/System/Library/PrivateFrameworks/PhoneNumbers.framework/Versions/A/PhoneNumbers" "$LOCAL_PN"
}

echo "=== MAIN EXECUTABLE ==="
patch_module "$BIN"

echo "=== LION ISLAND FRAMEWORK BINARIES ==="
patch_module "$FW/IMCore.framework/Versions/A/IMCore"
patch_module "$FW/IMCore.framework/Versions/A/Frameworks/IMFoundation.framework/Versions/A/IMFoundation"
patch_module "$FW/InstantMessage.framework/Versions/A/InstantMessage"
patch_module "$FW/InstantMessage.framework/Versions/A/Frameworks/IMRenderingFoundation.framework/Versions/A/IMRenderingFoundation"
patch_module "$FW/IMServicePlugIn.framework/Versions/A/Frameworks/IMServicePlugInSupport.framework/Versions/A/IMServicePlugInSupport"
patch_module "$FW/IMAVCore.framework/Versions/A/IMAVCore"

echo "=== IN-PROCESS iCHAT PLUG-INS ==="
if [ -d "$APP/Contents/PlugIns" ]; then
    find "$APP/Contents/PlugIns" -type f -print0 | while IFS= read -r -d '' FILE; do
        if otool -L "$FILE" >/dev/null 2>&1; then
            patch_module "$FILE"
        fi
    done
fi

echo "=== RESIDUAL SYSTEM MESSAGING REFS IN IN-PROCESS TARGETS ==="
check_file()
{
    FILE="$1"
    [ -f "$FILE" ] || return 0
    R=$(otool -L "$FILE" 2>/dev/null | grep -E '/System/Library/(Frameworks|PrivateFrameworks)/(IMCore|InstantMessage|DataDetectorsCore|PhoneNumbers)\.framework' || true)
    if [ -n "$R" ]; then
        echo "--- $FILE"
        echo "$R"
    fi
}

check_file "$BIN"
check_file "$FW/IMCore.framework/Versions/A/IMCore"
check_file "$FW/IMCore.framework/Versions/A/Frameworks/IMFoundation.framework/Versions/A/IMFoundation"
check_file "$FW/InstantMessage.framework/Versions/A/InstantMessage"
check_file "$FW/InstantMessage.framework/Versions/A/Frameworks/IMRenderingFoundation.framework/Versions/A/IMRenderingFoundation"
check_file "$FW/IMServicePlugIn.framework/Versions/A/Frameworks/IMServicePlugInSupport.framework/Versions/A/IMServicePlugInSupport"
check_file "$FW/IMAVCore.framework/Versions/A/IMAVCore"

if [ -d "$APP/Contents/PlugIns" ]; then
    find "$APP/Contents/PlugIns" -type f -print0 | while IFS= read -r -d '' FILE; do
        if otool -L "$FILE" >/dev/null 2>&1; then
            check_file "$FILE"
        fi
    done
fi

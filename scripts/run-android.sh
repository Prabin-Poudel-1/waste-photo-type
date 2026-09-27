#!/bin/sh
# Emulator or USB Android: forwarding keeps the backend laptop-only.
set -eu
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if command -v adb >/dev/null 2>&1; then
  adb_bin=$(command -v adb)
elif [ -x "${ANDROID_HOME:-$HOME/Library/Android/sdk}/platform-tools/adb" ]; then
  adb_bin="${ANDROID_HOME:-$HOME/Library/Android/sdk}/platform-tools/adb"
else
  echo 'Android SDK platform-tools are missing. Install them in Android Studio.' >&2
  exit 1
fi
if [ "$#" -eq 0 ]; then
  devices=$("$adb_bin" devices | awk 'NR > 1 && $2 == "device" {print $1}')
  count=$(printf '%s\n' "$devices" | awk 'NF {n++} END {print n+0}')
  if [ "$count" -ne 1 ]; then
    "$adb_bin" devices
    echo 'Start one emulator or connect one unlocked USB phone with USB debugging enabled.' >&2
    echo 'With several devices, run: sh scripts/run-android.sh DEVICE_SERIAL' >&2
    exit 1
  fi
  device_id=$devices
else
  device_id=$1
  shift
fi
"$adb_bin" -s "$device_id" reverse tcp:8082 tcp:8082
exec "$project_dir/scripts/flutterw" run -d "$device_id" --debug \
  --dart-define=API_BASE_URL=http://127.0.0.1:8082 \
  --dart-define=ANALYSIS_MODE=device "$@"

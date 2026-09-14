#!/usr/bin/env bash

set -u

APP_PROCESS_FILTER="${IOS_APP_PROCESS_FILTER:-Runner.app}"
BUNDLE_EXECUTABLE="${IOS_BUNDLE_EXECUTABLE:-/Runner.app/Runner}"
DEVICE_ID="${IOS_DEVICE_ID:-}"
TIMEOUT_SECONDS="${IOS_DEVICECTL_TIMEOUT_SECONDS:-10}"

log() {
  printf '[ios:terminate] %s\n' "$1"
}

skip() {
  log "$1; skipping."
  exit 0
}

if [ "$(uname -s)" != "Darwin" ]; then
  skip "not running on macOS"
fi

if ! command -v xcrun >/dev/null 2>&1; then
  skip "xcrun is not available"
fi

if ! xcrun devicectl --help >/dev/null 2>&1; then
  skip "devicectl is not available"
fi

if [ -z "$DEVICE_ID" ]; then
  devices_output="$(xcrun devicectl list devices --timeout "$TIMEOUT_SECONDS" 2>/dev/null || true)"
  DEVICE_ID="$(printf '%s\n' "$devices_output" | awk '
    /(iPhone|iPad|iPod)/ && /(connected|available|paired|developer|enabled)/ {
      for (i = 1; i <= NF; i++) {
        if ($i ~ /^[0-9A-Fa-f-]{25,}$/) {
          print $i
          exit
        }
      }
    }
  ')"
fi

if [ -z "$DEVICE_ID" ]; then
  skip "no connected iOS device found; set IOS_DEVICE_ID to force a device"
fi

output="$(xcrun devicectl device info processes \
  --device "$DEVICE_ID" \
  --filter "executable.path CONTAINS '$APP_PROCESS_FILTER'" \
  --columns '*' \
  --timeout "$TIMEOUT_SECONDS" 2>/dev/null || true)"

pid="$(printf '%s\n' "$output" | awk -v executable="$BUNDLE_EXECUTABLE" '$0 ~ executable && $0 !~ /PlugIns/ { print $1; exit }')"

if [ -z "$pid" ]; then
  log "app is not running on $DEVICE_ID."
  exit 0
fi

if xcrun devicectl device process terminate \
  --device "$DEVICE_ID" \
  --pid "$pid" \
  --kill \
  --timeout "$TIMEOUT_SECONDS" >/dev/null 2>&1; then
  log "terminated pid $pid on $DEVICE_ID."
else
  log "failed to terminate pid $pid on $DEVICE_ID; continuing."
fi

#!/bin/sh

WIFI_DEV=$(networksetup -listallhardwareports \
  | awk '/Wi-Fi/{getline; print $2; exit}')
[ -z "$WIFI_DEV" ] && WIFI_DEV="en0"

SUMMARY=$(ipconfig getsummary "$WIFI_DEV" 2>/dev/null)
LINK=$(echo "$SUMMARY" | awk '/LinkStatusActive/{print $3; exit}')

if [ "$LINK" != "TRUE" ]; then
  sketchybar --set "$NAME" icon="􀙈" label="Disconnected"
  exit 0
fi

SSID=$(echo "$SUMMARY" | awk -F ' : ' '/ SSID/{print $2; exit}')
case "$SSID" in
"" | "<redacted>") SSID="Connected" ;;
esac

sketchybar --set "$NAME" icon="􀙇" label="$SSID"

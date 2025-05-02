#!/usr/bin/env bash

# Source the icon map with all the application icons
source "$CONFIG_DIR/icon_map.sh"

# Create a cache directory if it doesn't exist
CACHE_DIR="$HOME/.cache/sketchybar"
mkdir -p "$CACHE_DIR"

# Cache file for icon mappings
ICON_CACHE="$CACHE_DIR/icon_cache.txt"

# Create the cache file if it doesn't exist
if [ ! -f "$ICON_CACHE" ]; then
  touch "$ICON_CACHE"
fi

# Check if the app is already in cache
APP_NAME="$1"
CACHED_ICON=$(grep "^$APP_NAME|" "$ICON_CACHE" | cut -d '|' -f2)

if [ -n "$CACHED_ICON" ]; then
  # Cache hit, return the icon
  echo "$CACHED_ICON"
  exit 0
fi

# Get icon from the mapping function
__icon_map "$APP_NAME"

if [ -n "$icon_result" ]; then
  echo "$APP_NAME|$icon_result" >>"$ICON_CACHE"
fi

echo "$icon_result"
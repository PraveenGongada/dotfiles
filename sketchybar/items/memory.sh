#!/bin/bash

USAGE="$(memory_pressure | grep "System-wide memory free percentage:" | awk '{ printf("%02.0f\n", 100-$5"%") }')%"

sketchybar --add item memory right \
  --set memory update_freq=15 \
  icon=􀧖 \
  label="$USAGE" \
  script="$PLUGIN_DIR/memory.sh"

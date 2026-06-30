#!/bin/bash

CORE_COUNT=$(sysctl -n machdep.cpu.thread_count)
CPU_PERCENT=$(ps -eo pcpu | awk -v c="$CORE_COUNT" '{sum+=$1} END {printf "%.0f\n", sum/c}')
sketchybar --set $NAME label="$CPU_PERCENT%"

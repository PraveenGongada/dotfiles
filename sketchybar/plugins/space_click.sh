#!/bin/sh

apps=$(aerospace list-windows --workspace $1 | awk -F '|' '{gsub(/^ *| *$/, "", $2); print $2}')
focused=$(aerospace list-workspaces --focused)

if [ "${apps}" = "" ] && [ "${focused}" != "$1" ]; then
  sketchybar --set space.$1 display=0
else
  aerospace workspace $1
fi

#!/bin/sh

# Some events send additional information specific to the event in the $INFO
# variable. E.g. the front_app_switched event sends the name of the newly
# focused application in the $INFO variable:
# https://felixkratz.github.io/SketchyBar/config/events#events-and-scripting

app_switched() {
  for m in $(aerospace list-monitors | awk '{print $1}'); do
    for sid in $(aerospace list-workspaces --monitor $m --visible); do
      
      apps=$( (echo "$INFO"; aerospace list-windows --monitor "$m" --workspace "$sid" \
      | awk -F '|' '{gsub(/^ *| *$/, "", $2); print $2}') \
      | awk '!seen[$0]++' | sort)

      icon_strip=""
      if [ "${apps}" != "" ]; then
        while read -r app; do
          icon_strip+=" $($CONFIG_DIR/plugins/icons.sh "$app")"
        done <<<"${apps}"
      else
        icon_strip=" —"
      fi

      sketchybar --animate sin 10 --set space.$sid label="$icon_strip"
    done
  done
}

if [ "$SENDER" = "front_app_switched" ]; then

  sketchybar --set $NAME label="$INFO" icon="$($CONFIG_DIR/plugins/icons.sh "$INFO")"

  app_switched
fi

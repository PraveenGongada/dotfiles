#!/bin/sh

source "$CONFIG_DIR/colors.sh"

update_icons() {
  m=$1
  sid=$2

  apps=$(aerospace list-windows --monitor "$m" --workspace "$sid" \
  | awk -F '|' '{gsub(/^ *| *$/, "", $2); if (!seen[$2]++) print $2}')

  icon_strip=""
  if [ "${apps}" != "" ]; then
    while read -r app; do
      icon_strip+=" $($CONFIG_DIR/plugins/icon_map.sh "$app")"
    done <<<"${apps}"
  else icon_strip=" —"
  fi

  sketchybar --animate sin 10 --set space.$sid label="$icon_strip"
}

app_switched() {
  for m in $(aerospace list-monitors | awk '{print $1}'); do
    for sid in $(aerospace list-workspaces --monitor $m --visible); do
      
      apps=$( (echo "$INFO"; aerospace list-windows --monitor "$m" --workspace "$sid" \
      | awk -F '|' '{gsub(/^ *| *$/, "", $2); print $2}') \
      | awk '!seen[$0]++')

      icon_strip=""
      if [ "${apps}" != "" ]; then
        while read -r app; do
          icon_strip+=" $($CONFIG_DIR/plugins/icon_map.sh "$app")"
        done <<<"${apps}"
      else
        icon_strip=" —"
      fi

      sketchybar --animate sin 10 --set space.$sid label="$icon_strip"

    done
  done
}

if [ "$SENDER" = "front_app_switched" ]; then

  app_switched

elif [[ "$SENDER" = "aerospace_workspace_change" ]]; then

  for m in $(aerospace list-monitors | awk '{print $1}'); do
    for sid in $(aerospace list-workspaces --monitor $m --visible); do

      sketchybar --set space.$sid display=$m

      update_icons "$m" "$sid"

      sketchybar --set space.$PREV_WORKSPACE background.drawing=off \
        label.color=$ACCENT_COLOR \
        icon.color=$ACCENT_COLOR

      if [ "$sid" = "$FOCUSED_WORKSPACE" ]; then 
        sketchybar --animate sin 10 --set space.$FOCUSED_WORKSPACE background.drawing=on \
        background.color=$ACCENT_COLOR \
        label.color=$BAR_COLOR \
        icon.color=$BAR_COLOR
      fi

      # can be done only when there are no apps
      update_icons "$m" "$PREV_WORKSPACE"

    done
  done
fi

#!/bin/sh

source "$CONFIG_DIR/colors.sh"

update_workspace_appearance() {
  local sid=$1
  local is_focused=$2
  
  if [ "$is_focused" = "true" ]; then
    sketchybar --set space.$sid background.drawing=on \
      background.color=$ACCENT_COLOR \
      label.color=$ITEM_COLOR \
      icon.color=$ITEM_COLOR
  else
    sketchybar --set space.$sid background.drawing=off \
      label.color=$ACCENT_COLOR \
      icon.color=$ACCENT_COLOR
  fi
}

update_icons() {
  m=$1
  sid=$2
  animate=$3

  apps=$(aerospace list-windows --monitor "$m" --workspace "$sid" \
  | awk -F '|' '{gsub(/^ *| *$/, "", $2); if (!seen[$2]++) print $2}' \
  | sort)

  icon_strip=""
  if [ "${apps}" != "" ]; then
    while read -r app; do
      icon_strip+=" $($CONFIG_DIR/plugins/icon_map.sh "$app")"
    done <<<"${apps}"
  else 
    icon_strip=" —"
  fi

  if [ "$animate" = "true" ]; then
    sketchybar --animate sin 10 --set space.$sid label="$icon_strip"
  else
    sketchybar --set space.$sid label="$icon_strip"
  fi
}

app_switched() {
  for m in $(aerospace list-monitors | awk '{print $1}'); do
    for sid in $(aerospace list-workspaces --monitor $m --visible); do
      
      apps=$( (echo "$INFO"; aerospace list-windows --monitor "$m" --workspace "$sid" \
      | awk -F '|' '{gsub(/^ *| *$/, "", $2); print $2}') \
      | awk '!seen[$0]++' | sort)

      icon_strip=""
      if [ "${apps}" != "" ]; then
        while read -r app; do
          icon_strip+=" $($CONFIG_DIR/plugins/icon_map.sh "$app")"
        done <<<"${apps}"
      else
        icon_strip=" —"
      fi

      sketchybar --set space.$sid label="$icon_strip"
    done
  done
}

if [ "$SENDER" = "front_app_switched" ]; then
  app_switched

elif [[ "$SENDER" = "aerospace_workspace_change" ]]; then
  update_workspace_appearance "$PREV_WORKSPACE" "false"
  update_workspace_appearance "$FOCUSED_WORKSPACE" "true"

  for m in $(aerospace list-monitors | awk '{print $1}'); do
    for sid in $(aerospace list-workspaces --monitor $m --visible); do
      sketchybar --set space.$sid display=$m

      update_icons "$m" "$sid" "true"
      
      update_icons "$m" "$PREV_WORKSPACE" "false"
      
      apps=$(aerospace list-windows --monitor "$m" --workspace "$sid" | wc -l)
      if [ "${apps}" -eq 0 ]; then
        sketchybar --set space.$sid display=0
      fi
    done
  done
fi

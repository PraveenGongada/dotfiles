#!/bin/bash

sketchybar --add event aerospace_workspace_change

for m in $(aerospace list-monitors | awk '{print $1}'); do
  for sid in $(aerospace list-workspaces --monitor $m); do
    sketchybar --add space space.$sid left \
      --set space.$sid space=$sid \
      icon=$sid \
      background.color=$TRANSPARENT \
      label.color=$ACCENT_COLOR \
      icon.color=$ACCENT_COLOR \
      display=$m \
      label.font="sketchybar-app-font:Regular:12.0" \
      icon.font="SF Pro:Semibold:12.0" \
      label.padding_right=10 \
      label.y_offset=-1 \
      click_script="$PLUGIN_DIR/space_click.sh $sid" \
      script="$PLUGIN_DIR/space.sh $sid" \
      --subscribe space.$sid aerospace_workspace_change front_app_switched

    apps=$(aerospace list-windows --monitor "$m" --workspace "$sid" |
      awk -F '|' '{gsub(/^ *| *$/, "", $2); if (!seen[$2]++) print $2}')

    icon_strip=""
    if [ "${apps}" != "" ]; then
      while read -r app; do
        icon_strip+=" $($PLUGIN_DIR/icon_map.sh "$app")"
      done <<<"${apps}"
    else
      icon_strip=" —"
    fi

    sketchybar --set space.$sid label="$icon_strip"

  done
  # It is to hide the empty spaces
  for empty_space in $(aerospace list-workspaces --monitor $m --empty); do
    sketchybar --set space.$empty_space display=0
  done
  for focus in $(aerospace list-workspaces --focused); do
    sketchybar --set space.$focus background.drawing=on \
      background.color=$ACCENT_COLOR \
      label.color=$ITEM_COLOR \
      icon.color=$ITEM_COLOR
  done
done

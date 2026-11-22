#!/bin/sh
payload=$(cat)
[ -n "$payload" ] || exit 0
dir="${XDG_CACHE_HOME:-$HOME/.cache}/claude-usage"
mkdir -p "$dir" 2>/dev/null
printf '%s' "$payload" > "$dir/.latest.$$" && mv -f "$dir/.latest.$$" "$dir/latest.json"
if [ -n "${HC_TERMINAL_ID:-}" ]; then
  terminal=$(printf '%s' "$HC_TERMINAL_ID" | tr -c 'A-Za-z0-9_.-' '_')
  printf '%s' "$payload" > "$dir/.terminal.$$" && mv -f "$dir/.terminal.$$" "$dir/terminal-$terminal.json"
fi
exit 0

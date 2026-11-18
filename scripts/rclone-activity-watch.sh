#!/usr/bin/env bash
set -u
state_dir="$HOME/.local/state/rclone"
log_file="$state_dir/activity.log"
mkdir -p "$state_dir"
touch "$log_file"
inotifywait -m -r -e create,close_write,moved_to,delete --format '%e|%w%f' /OneDrive 2>/dev/null | while IFS='|' read -r event path; do
  case "$event" in
    CREATE*|MOVED_TO*) action="Creado" ;;
    CLOSE_WRITE*) action="Modificado" ;;
    DELETE*) action="Eliminado" ;;
    *) action="$event" ;;
  esac
  printf '%s|%s|%s\n' "$(date '+%H:%M:%S')" "$action" "$path" >> "$log_file"
  notify-send -a "Rclone" "OneDrive: $action" "$path" 2>/dev/null || true
  tail -n 50 "$log_file" > "$log_file.tmp" && mv "$log_file.tmp" "$log_file"
done

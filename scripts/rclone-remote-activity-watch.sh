#!/usr/bin/env bash
set -u
state_dir="$HOME/.local/state/rclone"
log_file="$state_dir/activity.log"
snapshot="$state_dir/remote.snapshot"
next="$state_dir/remote.snapshot.next"
mkdir -p "$state_dir"
touch "$log_file"
while :; do
  rclone lsf --recursive --format "pt" --separator "|" onedrive: 2>/dev/null | sort -u > "$next" || true
  if [ -s "$snapshot" ]; then
    while IFS='|' read -r path stamp; do
      [ -z "$path" ] && continue
      if ! grep -Fqx "$path|$stamp" "$snapshot"; then
        local_path="/OneDrive/$path"
        printf '%s|Creado o modificado|%s\n' "$(date '+%H:%M:%S')" "$local_path" >> "$log_file"
        notify-send -a "Rclone" "OneDrive: archivo actualizado" "$local_path" 2>/dev/null || true
      fi
    done < "$next"
    tail -n 50 "$log_file" > "$log_file.tmp" && mv "$log_file.tmp" "$log_file"
  fi
  mv "$next" "$snapshot"
  sleep 5
done

#!/usr/bin/env bash
set -u
log_file="$HOME/.local/state/rclone/activity.log"

if [ ! -s "$log_file" ]; then
  printf '%s\n' "Sin actividad reciente"
  exit 0
fi

tail -n 2 "$log_file"

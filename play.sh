#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"
if [[ -x tools/godot ]]; then
  exec tools/godot --path . "$@"
elif command -v godot >/dev/null; then
  exec godot --path . "$@"
elif command -v godot4 >/dev/null; then
  exec godot4 --path . "$@"
else
  echo 'Open project.godot in Godot 4.7, or install Godot and run this script again.' >&2
  exit 1
fi

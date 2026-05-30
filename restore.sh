#!/usr/bin/env sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
config_dir="$repo_dir/config"
zed_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/zed"

mkdir -p "$zed_config_dir"

for file in settings.json keymap.json; do
  src="$config_dir/$file"
  dst="$zed_config_dir/$file"

  if [ ! -f "$src" ]; then
    printf 'Missing %s\n' "$src" >&2
    exit 1
  fi

  cp "$src" "$dst"
  printf 'Restored %s\n' "$file"
done

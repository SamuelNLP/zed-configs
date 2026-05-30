# Zed Configs

Sync personal Zed configuration across machines.

## Usage

Run `./backup.sh` to copy the current machine's Zed config into `config/`.

Run `./restore.sh` to copy `config/` into the current machine's Zed config directory.

The scripts use `${XDG_CONFIG_HOME:-$HOME/.config}/zed` as the Zed config directory.

#!/usr/bin/env bash
# Copy to Ubuntu/Debian and run: bash install-tmux-linux.sh
# Snapshot of Samuel's tmux config, with standard Linux Alt+arrow bindings.
set -euo pipefail

fail() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

[[ "$(uname -s)" == Linux ]] || fail "Run this installer on the target Linux machine."
[[ "$EUID" -ne 0 ]] || fail "Run as your normal user, without sudo. Only package installation uses sudo."
command -v apt-get >/dev/null 2>&1 || fail "This installer requires Ubuntu/Debian (apt-get)."

packages=()
command -v tmux >/dev/null 2>&1 || packages+=(tmux)
command -v git >/dev/null 2>&1 || packages+=(git)
if (( ${#packages[@]} > 0 )); then
    command -v sudo >/dev/null 2>&1 || fail "Ask an administrator to install: ${packages[*]}"
    sudo apt-get update
    sudo apt-get install -y "${packages[@]}"
fi

tpm_dir="$HOME/.tmux/plugins/tpm"
if [[ -e "$tpm_dir" || -L "$tpm_dir" ]]; then
    [[ -x "$tpm_dir/tpm" ]] || fail "$tpm_dir exists but has no executable TPM entry point. Move it aside and rerun."
else
    mkdir -p "$HOME/.tmux/plugins"
    git clone --depth 1 https://github.com/tmux-plugins/tpm.git "$tpm_dir"
fi

config="$HOME/.tmux.conf"
[[ ! -d "$config" ]] || fail "$config is a directory; expected a config file."
if [[ -e "$config" || -L "$config" ]]; then
    backup_dir="$(mktemp -d "$HOME/.tmux-config-backup.XXXXXXXX")"
    cp -P "$config" "$backup_dir/.tmux.conf"
    printf 'Existing config backed up to %s/.tmux.conf\n' "$backup_dir"
fi

temp_config="$(mktemp "$HOME/.tmux.conf.XXXXXXXX")"
trap 'rm -f "$temp_config"' EXIT
cat > "$temp_config" <<'TMUX_CONFIG'
# Use Ctrl+a as tmux prefix instead of Ctrl+b
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# Start windows and panes at 1
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on

# New tmux window in current directory
bind c new-window -c "#{pane_current_path}"

# Splits, keeping current directory
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"

# Reload config
bind r source-file ~/.tmux.conf \; display-message "tmux config reloaded"

# Alt+Up/Down to cycle panes (Left/Right used for window cycling)
bind -n M-Up select-pane -t :.-
bind -n M-Down select-pane -t :.+

set -g mouse on

# Bell handling: highlight tab blue when opencode-notifier rings the bell,
# no visual flash/message, no bell symbol
set -g visual-bell off
setw -g monitor-bell on

# Activity monitoring disabled (not desired)
setw -g monitor-activity off
set -g visual-activity off

# Window status styling (no #F flag anywhere, so no *`/`! symbols)
setw -g window-status-format " #I:#W "
setw -g window-status-current-format " #I:#W "
setw -g window-status-current-style "bg=black,fg=default"
setw -g window-status-bell-style "bg=blue,fg=white,bold"

# Alt+Left/Right to cycle windows (Zed sends \eb and \ef for Option+Left/Right)
bind -n M-b previous-window
bind -n M-f next-window

# Standard Alt+arrow sequences used by Linux terminals
bind -n M-Left previous-window
bind -n M-Right next-window

set -g status-left-length 60

set -g @plugin 'tmux-plugins/tpm'

# Keep this line at the very bottom of tmux.conf
run '~/.tmux/plugins/tpm/tpm'
TMUX_CONFIG

# Replace a config symlink itself rather than overwriting its target.
mv -f "$temp_config" "$config"

printf '\nInstalled %s and TPM.\n' "$config"
tmux -V
printf '\nStart a new session: tmux new -s main\n'
printf 'For an existing server, reload: tmux source-file ~/.tmux.conf\n'
printf '\nShortcuts: Ctrl+a then | or - to split; Ctrl+a then c for a window.\n'
printf 'Alt+Left/Right switches windows; Alt+Up/Down switches panes.\n'
printf 'Your terminal or desktop must pass those Alt shortcuts through to tmux.\n'

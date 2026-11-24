# config.fish
#
# Environment variables and the longer shell functions live in the bash
# dotfiles (see conf.d/bash.fish), so fish and bash share one copy of them.

status is-interactive; or status is-login; or return

# ssh-agent

# Plasma points SSH_AUTH_SOCK at the systemd user agent; do the same on TTYs
# and when an inherited socket is dead (herdr's agent symlink can dangle).
if not test -S "$SSH_AUTH_SOCK"; and test -S "$XDG_RUNTIME_DIR/ssh-agent.socket"
    set -gx SSH_AUTH_SOCK "$XDG_RUNTIME_DIR/ssh-agent.socket"
end

# language version managers

command -q pyenv; and pyenv init - --no-rehash fish | source
command -q pyenv; and pyenv virtualenv-init - fish | source
command -q nodenv; and nodenv init - fish | source
command -q rbenv; and rbenv init - --no-rehash fish | source

fish_add_path -g $HOME/.config/emacs/bin
fish_add_path -g $HOME/.config/yarn/global/node_modules/.bin
fish_add_path -g $HOME/.yarn/bin
fish_add_path -g $HOME/Code/work/product/bin

# the version manager inits prepend their shims even when PATH already has them
set -l unique_path
for dir in $PATH
    contains -- $dir $unique_path; or set -a unique_path $dir
end
set -gx PATH $unique_path
set -e unique_path dir

status is-interactive; or return

set -g fish_greeting

# callie colors for syntax highlighting and the completion pager, picking the
# light or dark variant from the terminal background
fish_config theme choose callie

# zoxide: z and zi jump to visited directories

command -q zoxide; and zoxide init fish | source

# vi mode, with a blinking bar in insert mode and a block otherwise

fish_vi_key_bindings
set -g fish_cursor_default block
set -g fish_cursor_insert line blink
set -g fish_cursor_replace_one underscore
set -g fish_cursor_visual block

# pick up commands run in other shells before each prompt, as the bash
# PROMPT_COMMAND does

function __history_merge --on-event fish_prompt
    history merge
end

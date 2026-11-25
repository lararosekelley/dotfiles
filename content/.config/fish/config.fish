# config.fish
#
# Environment variables come from the bash dotfiles (see conf.d/bash.fish),
# aliases from ~/.aliases (conf.d/abbreviations.fish), and most commands are
# scripts in ~/.bin, so fish and bash share one copy of each.

status is-interactive; or status is-login; or return

# language version managers

command -q pyenv; and pyenv init - --no-rehash fish | source
command -q pyenv; and test -d "$PYENV_ROOT/plugins/pyenv-virtualenv"
and pyenv virtualenv-init - fish | source
command -q nodenv; and nodenv init - fish | source
command -q rbenv; and rbenv init - --no-rehash fish | source

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

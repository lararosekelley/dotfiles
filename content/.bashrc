#!/usr/bin/env bash

# bashrc
#
# bash settings
# --------

# load dotfiles (order matters)

files=(
  ~/.functions
  ~/.aliases
  ~/.exports
  ~/.git_prompt
  ~/.environment # keep out of source control
)

for file in "${files[@]}"; do
  if [ -f "$file" ]; then
    # shellcheck disable=SC1090
    source "$file"
  fi
done

# bash options

options=(
  histappend
  cdspell
  globstar
  dotglob
  cmdhist
  dirspell
  nocaseglob
)

for option in "${options[@]}"; do
  shopt -s "$option"
done

if [[ $- == *i* ]]; then
  # `bind` needs readline, and a non-interactive shell has none
  bind "set show-all-if-ambiguous on"
fi

# bash completion

if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    source "/usr/share/bash-completion/bash_completion"
  fi
fi

# git completion

if [ -f /usr/share/bash-completion/completions/git ]; then
  source "/usr/share/bash-completion/completions/git"
  __git_complete g __git_main
fi

# kubernetes completion

if command -v kubectl > /dev/null; then
  # shellcheck source=/dev/null
  source <(kubectl completion bash)
  complete -o default -F __start_kubectl k
fi

for tool in helm k3d herdr tuios; do
  # shellcheck source=/dev/null
  command -v "$tool" > /dev/null && source <("$tool" completion bash)
done
unset tool

# ssh-agent

# Plasma points SSH_AUTH_SOCK at the systemd user agent; do the same on TTYs
# and when an inherited socket is dead (herdr's agent symlink can dangle).
if [ ! -S "${SSH_AUTH_SOCK:-}" ] && [ -S "${XDG_RUNTIME_DIR:-}/ssh-agent.socket" ]; then
  export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
fi

# pyenv

eval "$(pyenv init - --no-rehash bash)"
eval "$(pyenv virtualenv-init -)"

# nodenv

eval "$(nodenv init -)"

# rbenv

eval "$(rbenv init - --no-rehash bash)"

# ruby completion

if [ -f ~/Code/oss/completion-ruby/completion-ruby-all ]; then
  source "$HOME/Code/oss/completion-ruby/completion-ruby-all"
fi

# rust

if [ -f ~/.cargo/env ]; then
  # shellcheck disable=SC1091
  source "$HOME/.cargo/env"
fi

# load bash prompt

if [ -f ~/.bash_prompt ]; then
  source "$HOME/.bash_prompt"

  PROMPT_COMMAND="set_prompt; history -a; history -c; history -r"
fi

# zoxide: z and zi jump to visited directories. Initialized after
# PROMPT_COMMAND is set, since it adds its hook to it.

command -v zoxide > /dev/null && eval "$(zoxide init bash)"

path_prepend_if_missing "$HOME/.config/emacs/bin"
path_prepend_if_missing "$HOME/.config/yarn/global/node_modules/.bin"
path_prepend_if_missing "$HOME/.yarn/bin"

# Added by higharc setup
path_prepend_if_missing "$HOME/Code/work/product/bin"

# higharc shell completion
[ -f "$HOME/.higharc/completion.bash" ] && source "$HOME/.higharc/completion.bash"

path_dedup

export PATH

# added by navi setup
# shellcheck source=/dev/null
command -v navi > /dev/null && source <(navi completions bash)

# added by git-stk setup
# shellcheck source=/dev/null
command -v git-stk > /dev/null && source <(git stk completions bash)

# stk wrapper: up/down/top/bottom cd into the worktree holding the branch.
# A process cannot change its parent shell's directory, so git-stk prints the
# destination and this moves you. Every other command falls through to git stk.
stk() {
  case "$1" in
    up | down | top | bottom)
      local dest
      dest=$(git stk "$@" --from-path) || return
      [ -n "$dest" ] && { cd "$dest" || return; }
      ;;
    *) git stk "$@" ;;
  esac
}
complete -p git-stk > /dev/null 2>&1 && eval "$(complete -p git-stk | sed 's/ git-stk$/ stk/')"
# end git-stk setup

#!/usr/bin/env bash

# bashrc
#
# bash settings
# --------

# load dotfiles

files=(
  ~/.aliases
  ~/.exports
  ~/.functions
  ~/.git_prompt
  ~/.environment # placed last for precedence
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

bind "set show-all-if-ambiguous on"

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

# autojump

source "/usr/share/autojump/autojump.bash"

# pyenv

eval "$(pyenv init --path)"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# nodenv

eval "$(nodenv init -)"

# rbenv

eval "$(rbenv init -)"

# ruby completion

if [ -f ~/Code/oss/completion-ruby/completion-ruby-all ]; then
  source "$HOME/Code/oss/completion-ruby/completion-ruby-all"
fi

# load bash prompt

if [ -f ~/.bash_prompt ]; then
  source "$HOME/.bash_prompt"

  PROMPT_COMMAND="set_prompt; autojump_add_to_database; history -a; history -c; history -r"
fi

export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$HOME/.config/emacs/bin:$PATH"

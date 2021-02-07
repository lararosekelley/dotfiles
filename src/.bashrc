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
  ~/.gitprompt
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

# bash completion

brew_prefix="$(brew --prefix)"
completions_dir="$brew_prefix/etc/bash_completion.d"

if [[ -r "$brew_prefix/etc/profile.d/bash_completion.sh" ]]; then
  export BASH_COMPLETION_COMPAT_DIR
  BASH_COMPLETION_COMPAT_DIR="$completions_dir"

  # shellcheck disable=SC1090
  source "$brew_prefix/etc/profile.d/bash_completion.sh"
fi

bind "set show-all-if-ambiguous on"

# completion for macos "defaults" command

complete -W "NSGlobalDomain" defaults;

# git completion

if [[ -f "$completions_dir/git-completion.bash" ]]; then
  # shellcheck disable=SC1090
  source "$completions_dir/git-completion.bash"

  # completion for g alias
  __git_complete g __git_main
fi

# autojump

if [ -f "$brew_prefix/etc/profile.d/autojump.sh" ]; then
  # shellcheck disable=SC1090
  source "$brew_prefix/etc/profile.d/autojump.sh"
fi

# nodenv (node version manager)

if [[ -s "$brew_prefix/opt/nodenv" ]]; then
  eval "$(nodenv init -)"
fi

# rbenv (ruby version manager)

if [[ -s "$brew_prefix/opt/rbenv" ]]; then
  eval "$(rbenv init -)"
fi

# pyenv (python version manager)

if [[ -s "$brew_prefix/opt/pyenv" ]]; then
  eval "$(pyenv init -)"
fi

# pip

if command -v pip &> /dev/null; then
  if [[ ! -f "$completions_dir/pip.bash-completion" ]]; then
    pip completion --bash > "$completions_dir/pip.bash-completion"
  fi
fi

# pipenv

if command -v pipenv &> /dev/null; then
  if [[ ! -f "$completions_dir/pipenv.bash-completion" ]]; then
    pipenv --completion > "$completions_dir/pipenv.bash-completion"
  fi
fi

# poetry

if command -v poetry &> /dev/null; then
  if [[ ! -f "$completions_dir/poetry.bash-completion" ]]; then
    poetry completions bash > "$completions_dir/poetry.bash-completion"
  fi
fi

# load bash prompt

if [ -f ~/.bash_prompt ]; then
  # shellcheck disable=SC1090
  source ~/.bash_prompt
  PROMPT_COMMAND="set_prompt; autojump_add_to_database; history -a; history -c; history -r"
fi

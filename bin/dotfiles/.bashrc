#!/usr/bin/env bash

# bashrc
# --------

# bash settings

# load dotfiles
files=(
    ~/.aliases
    ~/.bash_prompt
    ~/.exports
    ~/.functions
    ~/.git-prompt.sh
    ~/.env # goes last to override any default settings
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
)

for option in "${options[@]}"; do
    shopt -s "$option"
done

# autojump
# shellcheck disable=SC1090
[[ -s "$(brew --prefix)/etc/profile.d/autojump.sh" ]] && source "$(brew --prefix)/etc/profile.d/autojump.sh"

# bash completion
if [ -f "$(brew --prefix)/etc/bash_completion" ]; then
    # shellcheck disable=SC1090
    source "$(brew --prefix)/etc/bash_completion"
fi

bind "set show-all-if-ambiguous on"

# nvm

if [[ -s "$(brew --prefix nvm)" ]]; then
    # shellcheck disable=SC1090
    source "$(brew --prefix nvm)/nvm.sh"
    NODE_VERSION=$(nvm current)
    nvm alias default "$NODE_VERSION" > /dev/null
fi

# rbenv

if [[ -s "$(brew --prefix rbenv)" ]]; then
    eval "$(rbenv init -)"
fi

# pyenv

if [[ -s "$(brew --prefix pyenv)" ]]; then
    eval "$(pyenv init -)"
fi

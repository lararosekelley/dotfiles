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
    cmdhist
    dirspell
    nocaseglob
)

for option in "${options[@]}"; do
    shopt -s "$option"
done

# autojump

if [ -f "$(brew --prefix)/etc/profile.d/autojump.sh" ]; then
    # shellcheck disable=SC1090
    source "$(brew --prefix)/etc/profile.d/autojump.sh"
fi

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

    # fix for homebrew nvm

    if [ -f "$(brew --prefix nvm)/etc/bash_completion.d/nvm" ]; then
        # shellcheck disable=SC1090
        source "$(brew --prefix nvm)/etc/bash_completion.d/nvm"
    fi

    # npm completion

    npm completion > /dev/null
fi

# rbenv

if [[ -s "$(brew --prefix rbenv)" ]]; then
    eval "$(rbenv init -)"
fi

# pyenv

if [[ -s "$(brew --prefix pyenv)" ]]; then
    eval "$(pyenv init -)"
    eval "$(pip completion --bash)"
fi

# pipenv

if command -v pipenv &> /dev/null; then
    eval "$(pipenv --completion)"
fi

# bash prompt

if [ -f ~/.bash_prompt ]; then
    # shellcheck disable=SC1090
    source ~/.bash_prompt
fi

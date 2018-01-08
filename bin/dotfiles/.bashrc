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

    npm completion >> ~/.npm_completion

    # shellcheck disable=SC1090
    source ~/.npm_completion
fi

# rbenv

if [[ -s "$(brew --prefix rbenv)" ]]; then
    eval "$(rbenv init -)"
fi

# pyenv

if [[ -s "$(brew --prefix pyenv)" ]]; then
    eval "$(pyenv init -)"

    if which pyenv-virtualenv-init > /dev/null; then
        eval "$(pyenv virtualenv-init -)";
    fi

    # pip completion
    _pip_completion() {
        COMPREPLY=( $( COMP_WORDS="${COMP_WORDS[*]}" \
                   COMP_CWORD=$COMP_CWORD \
                   PIP_AUTO_COMPLETE=1 $1 ) )
    }

    complete -o default -F _pip_completion pip
fi

# bash prompt

# shellcheck disable=SC1090
source ~/.bash_prompt

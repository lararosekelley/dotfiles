#!/usr/bin/env bash

# helper functions
# --------

function prompt_user() {
    read -p "$1 " -n 1
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        return 0
    fi

    return 1
}

function brew_install_upgrade() {
    if [[ $(brew ls --versions $1) ]]; then
        brew upgrade "$1"
    else
        brew install "$1"
    fi
}

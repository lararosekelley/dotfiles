#!/usr/bin/env bash

# python
# --------

# sets up python environment

PACKAGES=(
    csvkit
    flake8
    ipython
    jedi
    licenser
    uncommitted
)

log -v "configuring python..."

brew_install pyenv
brew_install pyenv-virtualenv

eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

pyenv rehash

PYTHON2_VERSION="$(pyenv install -l | grep -e '2.[0-9].[0-9]' | grep -v '[a-z]' | tail -1 | tr -d '[:space:]')"
PYTHON3_VERSION="$(pyenv install -l | grep -e '3.[0-9].[0-9]' | grep -v '[a-z]' | tail -1 | tr -d '[:space:]')"

pyenv install "$PYTHON2_VERSION"
pyenv install "$PYTHON3_VERSION"
pyenv global "$PYTHON2_VERSION" "$PYTHON3_VERSION"

# python 2

pip install --upgrade pip

for p in "${PACKAGES[@]}"; do
    pip install "$p"
done

#!/usr/bin/env bash

# python
#
# sets up python environment
# --------

PACKAGES=(
    csvkit
    flake8
    ipython
    jedi
    jupyter
    licenser
    matplotlib
    nose
    numpy
    pandas
    requests
    scipy
    sympy
    uncommitted
    vim-vint
)

log -v "configuring python..."

brew_install pyenv
brew_install pyenv-virtualenv
brew_install pyenv-pip-migrate

eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

pyenv rehash

PYTHON2_VERSION="$(pyenv install -l | grep -e '2.[0-9].[0-9]' | grep -v '[a-z]' | tail -1 | tr -d '[:space:]')"
PYTHON3_VERSION="$(pyenv install -l | grep -e '3.[0-9].[0-9]' | grep -v '[a-z]' | tail -1 | tr -d '[:space:]')"

pyenv install "$PYTHON2_VERSION"
pyenv install "$PYTHON3_VERSION"
pyenv global "$PYTHON2_VERSION" "$PYTHON3_VERSION"

# python 2 and 3

pip install --upgrade pip
pip3 install --upgrade pip

for p in "${PACKAGES[@]}"; do
    if prompt_user "install $p? (y/n)"; then
        pip install "$p"
        pip3 install "$p"
    fi
done

#!/usr/bin/env bash

# node
#
# sets up node environment
# --------

PACKAGES=(
    artillery
    bower
    eslint
    eslint-config-airbnb
    eslint-plugin-html
    eslint-plugin-import
    eslint-plugin-jsx-a11y
    eslint-plugin-react
    eslint-plugin-vue
    firebase-tools
    gulp-cli
    htmlhint
    mocha
    node-gyp
    nodemon
    nsp
    pm2
    stylelint
    tslint
    typescript
    vue-cli
)

log -v "setting up node..."

brew_install nvm
mkdir -p ~/.nvm
export NVM_DIR="$HOME/.nvm"

# shellcheck disable=SC1090

source "$(brew --prefix nvm)/nvm.sh"

# install and use latest LTS version

nvm install --lts
nvm use --delete-prefix lts/*
nvm alias default lts/*

for p in "${PACKAGES[@]}"; do
    if prompt_user "install $p? (y/n)"; then
        npm install -g "$p"
    fi
done

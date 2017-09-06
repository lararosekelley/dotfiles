#!/usr/bin/env bash

# node
#
# sets up node environment
# --------

PACKAGES=(
    artillery
    ava
    babel-eslint
    bower
    eslint
    eslint-plugin-ava
    eslint-plugin-import
    eslint-plugin-promise
    eslint-plugin-vue
    firebase-tools
    htmlhint
    jsonlint
    nodemon
    npm
    npm-check-updates
    nsp
    pm2
    stylelint
    stylelint-scss
)

log -v "setting up node..."

brew_install nvm
mkdir -p ~/.nvm
export NVM_DIR="$HOME/.nvm"

# shellcheck disable=SC1090

source "$(brew --prefix nvm)/nvm.sh"

# install and use latest stable version of node

nvm install node
nvm use node
nvm alias default node

# update npm to latest version

npm install -g npm@latest

for p in "${PACKAGES[@]}"; do
    if prompt_user "install $p? (y/n)"; then
        npm install -g "$p"
    fi
done

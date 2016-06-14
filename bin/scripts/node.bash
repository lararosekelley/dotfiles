#!/usr/bin/env bash

# node
# --------

# sets up node environment

PACKAGES=(
    csslint
    eslint
    gulp
    htmlhint
    nodemon
    pm2
    typescript
)

log -v "setting up node..."

brew_install nvm
mkdir -p ~/.nvm
export NVM_DIR="$HOME/.nvm"

# shellcheck disable=SC1090
source "$(brew --prefix nvm)/nvm.sh"

# "node" == latest version of node.js
nvm install node
nvm alias default node

for p in "${PACKAGES[@]}"; do
    npm install -g "$p"
done

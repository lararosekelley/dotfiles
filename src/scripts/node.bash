#!/usr/bin/env bash

# node
#
# sets up node environment
# --------

PACKAGES=(
    a11y
    artillery
    ava
    bower
    eslint
    eslint-plugin-ava
    eslint-plugin-import
    eslint-plugin-promise
    eslint-plugin-security
    eslint-plugin-vue
    firebase-tools
    flow-bin
    gulp-cli
    htmlhint
    jsdoc-to-markdown
    jsonlint
    livedown
    markdownlint-cli
    node-gyp
    npm
    npm-check-updates
    nsp
    pm2
    stylelint
    tap-dot
    ttystudio
    typescript
    vue-cli
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

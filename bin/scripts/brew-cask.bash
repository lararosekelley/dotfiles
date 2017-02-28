#!/usr/bin/env bash

# brew-cask
#
# installs mac apps with homebrew cask
# --------

PACKAGES=(
    1password
    appcleaner
    dash
    firefox
    google-cloud-sdk
    google-chrome
    mactex
    ngrok
    origami-studio
    paw
    postico
    sketch
    slack
    the-unarchiver
    transmission
    vagrant
    virtualbox
    xquartz
)

log -v "installing mac apps..."

for p in "${PACKAGES[@]}"; do
    if prompt_user "install $p? (y/n)"; then
        brew cask install "$p"
    fi
done

brew cask cleanup

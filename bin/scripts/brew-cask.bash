#!/usr/bin/env bash

# brew-cask
#
# installs mac apps with homebrew cask
# --------

PACKAGES=(
    1password
    appcleaner
    atom
    authy-desktop
    dash
    discord
    firefox
    google-chrome
    google-chrome-canary
    google-cloud-sdk
    java
    keycastr
    mactex
    medis
    ngrok
    origami-studio
    paw
    postico
    safari-technology-preview
    sketch
    slack
    the-unarchiver
    transmission
    vagrant
    virtualbox
    vlc
)

log -v "installing mac apps..."

for p in "${PACKAGES[@]}"; do
    if prompt_user "install $p? (y/n)"; then
        brew_cask_install "$p"
    fi
done

brew cask cleanup

#!/usr/bin/env bash

# brew-cask
#
# installs mac apps with homebrew cask
# --------

PACKAGES=(
    1password
    appcleaner
    dash
    discord
    dolphin
    evernote
    firefox
    google-chrome
    mactex
    medis
    ngrok
    omnifocus
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
        brew_cask_install "$p"
    fi
done

brew cask cleanup

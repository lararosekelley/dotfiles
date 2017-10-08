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
    blender
    cleanmymac
    dash
    discord
    dolphin
    expressions
    firefox
    firefoxnightly
    google-chrome
    google-chrome-canary
    google-cloud-sdk
    java
    keycastr
    mactex
    mongodb-compass
    ngrok
    numi
    opera
    origami-studio
    paw
    postico
    safari-technology-preview
    sip
    sketch
    sketchpacks
    slack
    the-unarchiver
    transmission
    transmit
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

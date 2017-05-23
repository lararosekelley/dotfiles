#!/usr/bin/env bash

# brew-cask
#
# installs mac apps with homebrew cask
# --------

PACKAGES=(
    1password
    adobe-acrobat-reader
    appcleaner
    dash
    discord
    dolphin
    evernote
    firefox
    google-cloud-sdk
    google-chrome
    mactex
    medis
    mono-mdk
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
    xamarin-ios
    xamarin-studio
    xquartz
)

log -v "installing mac apps..."

for p in "${PACKAGES[@]}"; do
    if prompt_user "install $p? (y/n)"; then
        brew_cask_install "$p"
    fi
done

brew cask cleanup

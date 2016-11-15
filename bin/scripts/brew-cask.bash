#!/usr/bin/env bash

# brew-cask
#
# installs mac apps with homebrew cask
# --------

PACKAGES=(
    appcleaner
    blender
    dolphin
    firefox
    github-desktop
    google-chrome
    lastpass
    openemu
    openscad
    paw
    sketch
    slack
    steam
    the-unarchiver
    transmission
    vagrant
    virtualbox
)

log -v "installing mac apps..."

for p in "${PACKAGES[@]}"; do
    if prompt_user "install $p? (y/n)"; then
        brew cask install "$p"
    fi
done

brew cask cleanup

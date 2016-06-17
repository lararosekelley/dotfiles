#!/usr/bin/env bash

# brew-cask
# --------

# installs mac apps with homebrew cask

PACKAGES=(
    appcleaner
    blender
    firefox
    github-desktop
    google-chrome
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
    prompt_user "install $p?"

    if [ $? == "0" ]; then
        brew cask install "$p"
    fi
done

brew cask cleanup &> /dev/null

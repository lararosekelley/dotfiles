#!/usr/bin/env bash
# installs brew cask packages

packages=(
    appcleaner
    atom
    firefox
    google-chrome
    java
    paw
    sketch
    slack
    utorrent
    vagrant
    virtualbox
    xquartz
)

if brew info brew-cask &>/dev/null; then
    brew cask install ${packages[@]};
else
    echo "brew cask not installed... aborting";
fi

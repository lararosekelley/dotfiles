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

if [ -x /usr/local/bin/brew-cask ]; then
    brew cask install ${packages[@]};
else
    echo "brew cask not installed to /usr/local/bin... aborting";
fi

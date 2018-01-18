#!/usr/bin/env bash

# brew-cask
#
# installs mac apps with homebrew cask
# --------

PACKAGES=(
    1password
    authy
    cleanmymac
    dash
    discord
    docker
    eclipse-java
    expressions
    firefox
    firefox-beta
    firefox-nightly
    google-chrome
    google-chrome-canary
    google-cloud-sdk
    iconjar
    java
    mongotron
    ngrok
    opera
    opera-beta
    opera-developer
    origami-studio
    paw
    postico
    safari-technology-preview
    sip
    sketch
    slack
    the-unarchiver
    transmission
    transmit
    vagrant
    virtualbox
)

log -v "installing mac apps..."

for p in "${PACKAGES[@]}"; do
    if prompt_user "install $p? (y/n)"; then
        brew_cask_install "$p"
    fi
done

brew cask cleanup

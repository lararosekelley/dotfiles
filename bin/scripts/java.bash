#!/usr/bin/env bash

# java
#
# sets up java environment
# --------

log -v "setting up java..."

brew_cask_install java
brew_cask_install eclipse-java

brew_install ant
brew_install gcc
brew_install gradle
brew_install make
brew_install maven
brew_install scala

# eclim (eclipse features for vim)

mkdir -p ~/.eclim-repo
git clone https://github.com/ervandew/eclim ~/.eclim-repo

cd ~/.eclim-repo
ant -Declipse.home=/Applications/Eclipse \Java.app/Contents/Eclipse

cd || exit
rm -rf ~/.eclim-repo

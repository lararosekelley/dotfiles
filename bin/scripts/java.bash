#!/usr/bin/env bash

# java
#
# sets up java environment
# --------

log -v "setting up java..."

brew_cask_install java
brew_cask_install eclipse-java

brew_install ant
brew_install gradle
brew_install maven
brew_install scala

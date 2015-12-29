#!/usr/bin/env bash

# update everything

brew update
brew upgrade --all

# install programs

brew cask install appcleaner
brew cask install atom
brew cask install firefox
brew cask install google-chrome
brew cask install java
brew cask install paw
brew cask install sketch
brew cask install slack
brew cask install steam
brew cask install the-unarchiver
brew cask install utorrent
brew cask install vagrant
brew cask install virtualbox
brew cask install xquartz

# done

brew cleanup
brew cask cleanup

#!/usr/bin/env bash

# settings
# --------

# changes mac settings to reasonable defaults
# adapted from https://github.com/mathiasbynens/dotfiles/blob/master/.osx

# table of contents
# --------
# 1. general & finder
# 2. mouse, trackpad, accessories
# --------

# 1. general & finder
# 2. mouse, trackpad, accessories
# --------

# show scrollbars automatically
defaults write NSGlobalDomain AppleShowScrollBars -string "Automatic"

# check for software updates daily
defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1

# expand save panel by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# set appearance & highlight color to graphite
defaults write NSGlobalDomain AppleAquaColorVariant -int 6
defaults write NSGlobalDomain AppleHighlightColor -string "0.847059 0.847059 0.862745"

# change minimize/maximize window effect
defaults write com.apple.dock mineffect -string "scale"

# minimize windows into their application’s icon
defaults write com.apple.dock minimize-to-application -bool true

# animate opening applications from the Dock
defaults write com.apple.dock launchanim -bool true

# show indicator lights for open applications in the Dock
defaults write com.apple.dock show-process-indicators -bool true

# set sidebar icon size to medium
defaults write NSGlobalDomain NSTableViewDefaultSizeMode -int 2

# finder: show hidden files by default
defaults write com.apple.finder AppleShowAllFiles -bool true

# finder: show files in column view
defaults write com.apple.finder FXPreferredViewStyle -string "clmv"

# don't warn when emptying trash
defaults write com.apple.finder WarnOnEmptyTrash -bool false

# show file extensions
defaults write NSGlobalDomain AppleShowAllExtensions -int 1

# when performing a search, search the current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# disable the warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# shrink windows on double-click
defaults write NSGlobalDomain AppleMiniaturizeOnDoubleClick -int 1

# disable Dashboard
defaults write com.apple.dashboard mcx-disabled -bool true

# don’t show Dashboard as a Space
defaults write com.apple.dock dashboard-in-overlay -bool true

# 2. mouse, trackpad, accessories
# --------

# enable tap to click for this user and for the login screen
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# increase bluetooth sound quality
defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40

# done
for app in "cfprefsd" "Dock" "Finder" "SystemUIServer"; do
	killall "${app}" &> /dev/null
done

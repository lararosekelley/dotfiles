#!/usr/bin/env bash

# terminal
# --------

# sets up the mac terminal app for development work

log -v "setting up terminal..."

cp "$1"/themes/com.apple.Terminal.plist ~/Library/Preferences/com.apple.Terminal.plist
defaults read com.apple.Terminal &> /dev/null

#!/usr/bin/env bash

# helpers
# --------

# useful utility functions for osx.bash

# asks the user for input
#
# args:
#   $1 - (string) prompt for user
#
# returns:
#   0 - if reply is Y or y
#   1 - otherwise
#
function prompt_user() {
    read -e -p "$1 "
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        return 0
    fi

    return 1
}

# installs or upgrades a brew package
#
# args:
#   $1 - (string) brew package name
#
function brew_install() {
    if [[ $(brew ls --versions "$1") ]]; then
        brew upgrade "$1"
    else
        brew install "$1"
    fi
}

# checks if computer can run the osx.sh script
#
# returns:
#   0 - if $OS == $VERSION
#   1 - otherwise
#
function os_eligible() {
    VERSION="10.11"
    OS=$(sw_vers -productVersion | awk -F '.' '{print $1 "." $2}')

    if [ "$OS" != "$VERSION" ]; then
        return 1
    fi

    return 0
}

# logs info to stdout & a debug file
#
# args:
#   $1 - (boolean) whether or not to log to stdout
#   $2 - (number) log level (warn=1, error=2)
#
function log() {
    LOGFILE=~/.osx.log
    INFO=$(tput sgr0)
    ERROR=$(tput setaf 124)
    WARN=$(tput setaf 136)


}

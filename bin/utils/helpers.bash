#!/usr/bin/env bash

# helpers
#
# useful utility functions for osx.bash
# --------

# asks the user to approve or deny something
#
# params:
#   prompt - what to ask the user to approve
#
# usage: prompt_user prompt
#
# returns:
#   0 - if reply is Y or y
#   1 - if reply is anything else
#
function prompt_user() {
    if [ -z "$1" ]; then
        echo "Usage: ${FUNCNAME[0]} prompt"
        return 1
    fi

    read -r -e -p "$1 "
    echo ""

    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        return 0
    fi

    return 1
}

# installs or upgrades a brew package if needed
#
# params:
#   package: brew package to install
#
# usage: brew_install package
#
function brew_install() {
    if [ -z "$1" ]; then
        echo "Usage: ${FUNCNAME[0]} package"
        return 1
    fi

    if brew ls --versions "$1" &> /dev/null; then
        if brew outdated | grep "$1" &> /dev/null; then
            brew upgrade "$1"
        fi
    else
        brew install "$1"
    fi
}

# installs or upgrades a brew cask app
#
# params:
#   package: mac app to install
#
# usage: brew_cask_install package
#
function brew_cask_install() {
    if [ -z "$1" ]; then
        echo "Usage: ${FUNCNAME[0]} package"
        return 1
    fi

    if brew cask ls --versions "$1" &> /dev/null; then
        brew cask reinstall "$1"
    else
        brew cask install "$1"
    fi
}

# checks if computer can run the osx.bash script
#
# returns:
#   0 - if $OS == $VERSION
#   1 - otherwise
#
function os_eligible() {
    VERSION="10.12"
    OS=$(sw_vers -productVersion | awk -F '.' '{print $1 "." $2}')

    if [ "$OS" != "$VERSION" ]; then
        return 1
    fi

    return 0
}

# logs info to stdout & a debug file
#
# params:
#   level - log level
#   text - text to log
#
# usage: log [-v] [-l level] text
#
# flags:
#   -v          verbose mode: log to stdout
#   -l level    log level: INFO, WARN, ERROR
#
function log() {
    logfile=$(pwd)/.setup.log
    verbose=0
    level="INFO"

    local OPTIND
    while getopts "vl:" opt; do
        case "$opt" in
            v) verbose=1 ;;
            l) level="$OPTARG" ;;
        esac
    done

    shift "$((OPTIND-1))"

    if [[ "$verbose" -eq 1 ]]; then
        echo "[$level]: $(date '+%m-%d-%Y %r') - $1"
    fi

    echo "[$level]: $(date '+%m-%d-%Y %r') - $1" >> "$logfile"
}

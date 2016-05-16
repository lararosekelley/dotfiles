#!/usr/bin/env bash

# helpers
# --------

# useful utility functions for osx.bash

# asks the user for input
#
# usage: prompt_user prompt
#
# returns:
#   0 - if reply is Y or y
#   1 - otherwise
#
function prompt_user() {
    if [ -z "$1" ]; then
        echo "Usage: ${FUNCNAME[0]} prompt"
        return 1
    fi

    read -e -p "$1 "
    echo ""

    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        return 0
    fi

    return 1
}

# installs or upgrades a brew package
#
# usage: brew_install package
#
function brew_install() {
    if [ -z "$1" ]; then
        echo "Usage: ${FUNCNAME[0]} package"
        return 1
    fi

    if [[ $(brew ls --versions "$1") ]]; then
        brew upgrade "$1" &> /dev/null
    else
        brew install "$1" &> /dev/null
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
# usage: log [-v] [-l level] text
#
# flags:
#   -v          verbose mode: log to stdout
#   -l level    log level: INFO, WARN, ERROR
#
function log() {
    logfile=$(pwd)/.osx.log
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

    echo "[$level]: $(date '+%m-%d-%Y %r') - $1" >> $logfile
}

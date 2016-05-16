#!/usr/bin/env bash

# osx
# --------

# bootstraps an apple computer for development work

# table of contents
# --------
# 1. global variables
# 2. setup
# 3. command line tools
# 4. homebrew
# 5. programming languages
# 6. mac apps
# 7. dotfiles
# 8. terminal
# 9. vim
# 10. atom
# --------

# 1. global variables
# --------

OSX_DIR=~/.osx
REPO_URL="https://github.com/tylucaskelley/osx/tarball/master"

# 2. setup
# --------

if [ -d $OSX_DIR ]; then
    rm -rf $OSX_DIR
fi

mkdir -p $OSX_DIR
curl -sL $REPO_URL | tar zx -C $OSX_DIR --strip-components 1

# shellcheck disable=SC1090
source $OSX_DIR/bin/utils/helpers.bash

os_eligible

if [ $? != "0" ]; then
    log -vl ERROR "os version too old to continue"
    exit 1
fi

# 3. command line tools
# --------

xcode-select -p &> /dev/null

if [ $? != "0" ]; then
    log -v "installing xcode command line tools..."
    touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
    XCODE=$(softwareupdate -l | grep "\*.*Command Line" | head -n 1 | awk -F"*" '{print $2}' | sed -e 's/^ *//' | tr -d '\n')
    softwareupdate -i $XCODE &> /dev/null
    rm /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
else
    log -v "xcode command line tools already installed"
fi

# 4. homebrew
# --------

brew help &> /dev/null

if [ $? != "0" ]; then
    log -v "installing homebrew..."
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
    log -v "homebrew already installed"
fi

# shellcheck disable=SC1090
source $OSX_DIR/bin/scripts/brew.bash

# 5. programming languages
# --------

log -v "installing programming languages..."

# go

prompt_user "install go?"

if [ $? == "0" ]; then
    # shellcheck disable=SC1090
    source $OSX_DIR/bin/scripts/go.bash
fi

# java

prompt_user "install java?"

if [ $? == "0" ]; then
    # shellcheck disable=SC1090
    source $OSX_DIR/bin/scripts/java.bash
fi

# node

prompt_user "install node?"

if [ $? == "0" ]; then
    # shellcheck disable=SC1090
    source $OSX_DIR/bin/scripts/node.bash
fi

# perl

prompt_user "install perl?"

if [ $? == "0" ]; then
    # shellcheck disable=SC1090
    source $OSX_DIR/bin/scripts/perl.bash
fi

# php

prompt_user "install php?"

if [ $? == "0" ]; then
    # shellcheck disable=SC1090
    source $OSX_DIR/bin/scripts/php.bash
fi

# python

prompt_user "install python?"

if [ $? == "0" ]; then
    # shellcheck disable=SC1090
    source $OSX_DIR/bin/scripts/python.bash
fi

# ruby

prompt_user "install ruby?"

if [ $? == "0" ]; then
    # shellcheck disable=SC1090
    source $OSX_DIR/bin/scripts/ruby.bash
fi

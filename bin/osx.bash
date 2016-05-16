#!/usr/bin/env bash

# osx
# --------

# bootstraps an apple computer for development work

# table of contents
# --------
# 1. global variables
# 2. setup & mac settings
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
REPO_URL="https://github.com/tylucaskelley/osx/tarball/v2"

# 2. setup & mac settings
# --------

if [ -d "$OSX_DIR" ]; then
    rm -rf "$OSX_DIR"
fi

mkdir -p "$OSX_DIR"
curl -sL "$REPO_URL" | tar zx -C "$OSX_DIR" --strip-components 1

# shellcheck disable=SC1090
source "$OSX_DIR"/bin/utils/helpers.bash

os_eligible

if [ "$?" != "0" ]; then
    log -vl ERROR "os version too old to continue"
    exit 1
fi

prompt_user "change mac settings to reasonable defaults?"

if [ "$?" == "0" ]; then
    # shellcheck disable=SC1090
    source "$OSX_DIR"/bin/scripts/settings.bash
fi

# 3. command line tools
# --------

xcode-select -p &> /dev/null

if [ "$?" != "0" ]; then
    log -v "installing xcode command line tools..."
    touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
    XCODE=$(softwareupdate -l | grep "\*.*Command Line" | head -n 1 | awk -F"*" '{print $2}' | sed -e 's/^ *//' | tr -d '\n')
    softwareupdate -i "$XCODE" &> /dev/null
    rm /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
else
    log -v "xcode command line tools already installed"
fi

# 4. homebrew
# --------

brew help &> /dev/null

if [ "$?" != "0" ]; then
    log -v "installing homebrew..."
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
    log -v "homebrew already installed"
fi

# shellcheck disable=SC1090
source "$OSX_DIR"/bin/scripts/brew.bash

# 5. programming languages
# --------

log -v "installing programming languages..."

# go

prompt_user "install go?"

if [ "$?" == "0" ]; then
    # shellcheck disable=SC1090
    source "$OSX_DIR"/bin/scripts/go.bash
fi

# java

prompt_user "install java?"

if [ "$?" == "0" ]; then
    # shellcheck disable=SC1090
    source "$OSX_DIR"/bin/scripts/java.bash
fi

# node

prompt_user "install node?"

if [ "$?" == "0" ]; then
    # shellcheck disable=SC1090
    source "$OSX_DIR"/bin/scripts/node.bash
fi

# python

prompt_user "install python?"

if [ "$?" == "0" ]; then
    # shellcheck disable=SC1090
    source "$OSX_DIR"/bin/scripts/python.bash
fi

# ruby

prompt_user "install ruby?"

if [ "$?" == "0" ]; then
    # shellcheck disable=SC1090
    source "$OSX_DIR"/bin/scripts/ruby.bash
fi

# 6. mac apps
# --------

prompt_user "install mac apps via brew cask?"

if [ "$?" == "0" ]; then
    # shellcheck disable=SC1090
    source "$OSX_DIR"/bin/scripts/brew-cask.bash
fi

# 7. dotfiles
# --------

log -v "copying dotfiles to $(echo ~)..."

cp -a "$OSX_DIR"/bin/dotfiles/. ~
rm ~/.vimrc # wait until vim setup

# 8. terminal
# --------

prompt_user "change terminal theme?"

if [ "$?" == "0" ]; then
    # shellcheck disable=SC1090
    source "$OSX_DIR"/bin/scripts/terminal.bash
fi

# 9. vim
# --------

prompt_user "set up vim editor?"

if [ "$?" == "0" ]; then
    # shellcheck disable=SC1090
    source "$OSX_DIR"/bin/scripts/vim.bash
fi

# 10. atom
# --------

prompt_user "set up atom editor?"

if [ "$?" == "0" ]; then
    # shellcheck disable=SC1090
    source "$OSX_DIR"/bin/scripts/atom.bash
fi

# done

read -d '' exit_msg << EOF
***********************************************
**    all done!                              **
**                                           **
**    please leave feedback:                 **
**    github.com/tylucaskelley/osx/issues    **
***********************************************
EOF

echo "\n\n$exit_msg\n\n"

#!/usr/bin/env bash

# osx
# --------

# bootstraps an apple computer for development work

# table of contents
# --------
# 1.  global variables
# 2.  setup
# 3.  command line tools
# 4.  homebrew
# 5.  programming languages
# 6.  mac apps
# 7.  dotfiles
# 8.  terminal
# 9.  vim
# 10. cleanup
# --------

# 1. global variables
# --------

OSX_DIR=~/.osx
REPO_URL="https://github.com/tylucaskelley/osx/tarball/master"

# 2. setup & mac settings
# --------

echo "please enter your password: "

sudo -v

while true; do
    sudo -n true
    sleep 60
    kill -0 "$$" || exit
done 2>/dev/null &

if [ -d "$OSX_DIR" ]; then
    rm -rf "$OSX_DIR"
fi

mkdir -p "$OSX_DIR"
curl -sL "$REPO_URL" | tar zx -C "$OSX_DIR" --strip-components 1

# shellcheck disable=SC1090
source "$OSX_DIR"/bin/utils/helpers.bash

os_eligible

if [ "$?" != "0" ]; then
    log -vl ERROR "aborting; os version must be 10.11 to continue"
    exit 1
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
    GO_ACCEPTED=1

    # shellcheck disable=SC1090
    source "$OSX_DIR"/bin/scripts/go.bash
fi

# java

prompt_user "install java?"

if [ "$?" == "0" ]; then
    JAVA_ACCEPTED=1

    # shellcheck disable=SC1090
    source "$OSX_DIR"/bin/scripts/java.bash
fi

# node

prompt_user "install node?"

if [ "$?" == "0" ]; then
    NODE_ACCEPTED=1

    # shellcheck disable=SC1090
    source "$OSX_DIR"/bin/scripts/node.bash
fi

# python

prompt_user "install python?"

if [ "$?" == "0" ]; then
    PYTHON_ACCEPTED=1

    # shellcheck disable=SC1090
    source "$OSX_DIR"/bin/scripts/python.bash
fi

# ruby

prompt_user "install ruby?"

if [ "$?" == "0" ]; then
    RUBY_ACCEPTED=1

    # shellcheck disable=SC1090
    source "$OSX_DIR"/bin/scripts/ruby.bash
fi

# 6. mac apps
# --------

prompt_user "install mac apps via brew cask?"

if [ "$?" == "0" ]; then
    BREW_CASK_ACCEPTED=1

    # shellcheck disable=SC1090
    source "$OSX_DIR"/bin/scripts/brew-cask.bash
fi

# 7. dotfiles
# --------


log -v "copying dotfiles to home directory..."

cp -a "$OSX_DIR"/bin/dotfiles/. ~
rm ~/.vimrc # wait until vim setup

# set up .env

log -v "setting up ~/.env file..."

touch ~/.env

echo -n "Enter your name: "
read -r user_name

echo -n "Enter your email address: "
read -r user_email

# copy to file

# shellcheck disable=SC2129
echo "# env" >> ~/.env
echo "# --------" >> ~/.env
echo "GIT_AUTHOR_NAME=\"${user_name}\"" >> ~/.env
echo "GIT_AUTHOR_EMAIL=\"${user_email}\"" >> ~/.env
echo "GIT_COMMITTER_NAME=\"${user_name}\"" >> ~/.env
echo "GIT_COMMITTER_EMAIL=\"${user_email}\"" >> ~/.env
echo "git config --global user.name \"${user_name}\"" >> ~/.env
echo "git config --global user.email \"${user_email}\"" >> ~/.env

# 8. terminal
# --------

prompt_user "change terminal theme?"

if [ "$?" == "0" ]; then
    TERMINAL_ACCEPTED=1

    # shellcheck disable=SC1090
    source "$OSX_DIR"/bin/scripts/terminal.bash "$OSX_DIR"
fi

# 9. vim
# --------

prompt_user "set up vim editor?"

if [ "$?" == "0" ]; then
    VIM_ACCEPTED=1

    # shellcheck disable=SC1090
    source "$OSX_DIR"/bin/scripts/vim.bash "$OSX_DIR"
fi

# 10. cleanup
# --------

echo "summary of changes:"

echo "-- xcode command line tools installed --"

echo "-- dotfiles copied to home directory --"

BREW_PACKAGES="$(brew list)"
echo "-- brew packages installed --" && echo "$BREW_PACKAGES"

if [ "$BREW_CASK_ACCEPTED" == "1" ]; then
    BREW_CASK_PACKAGES="$(brew cask list)"
    echo "-- mac apps installed --" && echo "$BREW_CASK_PACKAGES"
fi

if [ "$TERMINAL_ACCEPTED" == "$1" ]; then
    echo "-- terminal theme changed --"
fi

if [ "$VIM_ACCEPTED" == "1" ]; then
    echo "-- vim installed & configured in ~/.vim --"
fi

if [ "$PYTHON_ACCEPTED" == "1" ]; then
    PY2_VERSION="$(pyenv install -l | grep -e '2.[0-9].[0-9]' | grep -v '[a-z]' | tail -1)"
    PY3_VERSION="$(pyenv install -l | grep -e '3.[0-9].[0-9]' | grep -v '[a-z]' | tail -1)"
    echo "-- python $PY2_VERSION, $PY3_VERSION installed & configured in ~/.pyenv --"
fi

if [ "$RUBY_ACCEPTED" == "1" ]; then
    RB_VERSION="$(ruby --version | cut -d ' ' -f 2 | cut -d p -f 1)"
    echo "-- ruby $RB_VERSION installed & configured in ~/.rbenv --"
fi

if [ "$JAVA_ACCEPTED" == "1" ]; then
    JAVA_VERSION="$(javac -version 2>&1 | cut -d ' ' -f 2)"
    echo "-- java $JAVA_VERSION installed & maven installed --"
fi

if [ "$GO_ACCEPTED" == "1" ]; then
    GO_VERSION="$(go version | cut -d ' ' -f 3 | cut -d o -f 2)"
    echo "-- go $GO_VERSION installed & configured in ~/.go --"
fi

if [ "$NODE_ACCEPTED" == "1" ]; then
    NODE_VERSION="$(node -v)"
    echo "-- node.js $NODE_VERSION installed & configured in ~/.nvm --"
fi

echo -e "\n\nall done! \nplease leave feedback: \n$REPO_URL"

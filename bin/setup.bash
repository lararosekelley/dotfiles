#!/usr/bin/env bash

# setup.sh
# --------

# My automated development setup

# table of contents
# --------
#
# 1.    global variables
# 2.    setup
# 3.    command line tools
# 4.    homebrew
# 5.    programming languages
# 6.    mac apps
# 7.    dotfiles
# 8.    ssh
# 9.    terminal
# 10.   vim
# 11.   cleanup
#
# --------

# 1. global variables
# --------

SETUP_DIR=~/.setup
REPO_URL="https://github.com/tylucaskelley/setup.sh/tarball/master"
ISSUES_URL="https://github.com/tylucaskelley/setup.sh/issues/new"

# 2. setup
# --------

echo "please enter your password: "

sudo -v

while true; do
    sudo -n true
    sleep 60
    kill -0 "$$" || exit
done 2>/dev/null &

if [ -d "$SETUP_DIR" ]; then
    rm -rf "$SETUP_DIR"
fi

mkdir -p "$SETUP_DIR"
curl -sL "$REPO_URL" | tar zx -C "$SETUP_DIR" --strip-components 1

# shellcheck disable=SC1090
source "$SETUP_DIR"/bin/utils/helpers.bash

if ! os_eligible; then
    log -vl ERROR "fatal: os version must be 10.11 or higher to continue"
    exit 1
fi

# 3. command line tools
# --------

if ! xcode-select -p &> /dev/null; then
    log -v "installing xcode command line tools..."

    touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress

    XCODE=$(softwareupdate -l | grep "\*.*Command Line" | head -n 1 | awk -F"*" '{print $2}' | sed -e 's/^ *//' | tr -d '\n')

    softwareupdate -i "$XCODE" --verbose
    rm /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
else
    log -v "xcode command line tools already installed"
fi

# update all software

log -v "updating system..."

softwareupdate --install --all

# 4. homebrew
# --------

if ! brew help &> /dev/null; then
    log -v "installing homebrew..."
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
    log -v "homebrew already installed"
fi

# shellcheck disable=SC1090
source "$SETUP_DIR"/bin/scripts/brew.bash

# 5. programming languages
# --------

log -v "installing programming languages..."

# go

if prompt_user "install go? (y/n)"; then
    GO_ACCEPTED=1

    # shellcheck disable=SC1090
    source "$SETUP_DIR"/bin/scripts/go.bash
fi

# java

if prompt_user "install java? (y/n)"; then
    JAVA_ACCEPTED=1

    # shellcheck disable=SC1090
    source "$SETUP_DIR"/bin/scripts/java.bash
fi

# node

if prompt_user "install node? (y/n)"; then
    NODE_ACCEPTED=1

    # shellcheck disable=SC1090
    source "$SETUP_DIR"/bin/scripts/node.bash
fi

if prompt_user "install php? (y/n)"; then
    PHP_ACCEPTED=1

    # shellcheck disable=SC1090
    source "$SETUP_DIR"/bin/scripts/php.bash
fi

# python

if prompt_user "install python? (y/n)"; then
    PYTHON_ACCEPTED=1

    # shellcheck disable=SC1090
    source "$SETUP_DIR"/bin/scripts/python.bash
fi

# ruby

if prompt_user "install ruby? (y/n)"; then
    RUBY_ACCEPTED=1

    # shellcheck disable=SC1090
    source "$SETUP_DIR"/bin/scripts/ruby.bash
fi

# rust

if prompt_user "install rust? (y/n)"; then
    RUST_ACCEPTED=1

    # shellcheck disable=SC1090
    source "$SETUP_DIR"/bin/scripts/rust.bash
fi

# 6. mac apps
# --------

if prompt_user "install mac apps with homebrew cask? (y/n)"; then
    BREW_CASK_ACCEPTED=1

    # shellcheck disable=SC1090
    source "$SETUP_DIR"/bin/scripts/brew-cask.bash
fi

# 7. dotfiles
# --------

log -v "copying dotfiles to home directory..."

cp -a "$SETUP_DIR"/bin/dotfiles/. ~
rm ~/.vimrc # wait until vim setup

# set up .env

log -v "setting up ~/.env file..."

touch ~/.env
echo -n "Enter your name: " && read -r user_name
echo -n "Enter your email address: " && read -r user_email

cat > ~/.env << EOL
# env
# --------

GIT_AUTHOR_NAME='${user_name}'
GIT_AUTHOR_EMAIL='${user_email}'
GIT_COMMITTER_NAME='${user_name}'
GIT_COMMITTER_EMAIL='${user_email}'
EOL

log -v "setting git name and email..."

git config --global user.name "${user_name}"
git config --global user.email "${user_email}"

# 8. ssh
# --------

if prompt_user "create an ssh key and add it to your keychain? this will delete the contents of ~/.ssh. (y/n)"; then
    SSH_ACCEPTED=1

    # shellcheck disable=SC1090
    source "$SETUP_DIR"/bin/scripts/ssh.bash
fi

# 9. terminal
# --------

if prompt_user "change terminal theme?"; then
    TERMINAL_ACCEPTED=1

    # shellcheck disable=SC1090
    source "$SETUP_DIR"/bin/scripts/terminal.bash "$SETUP_DIR"
fi

# 10. vim
# --------

if prompt_user "set up vim editor?"; then
    VIM_ACCEPTED=1

    # shellcheck disable=SC1090
    source "$SETUP_DIR"/bin/scripts/vim.bash "$SETUP_DIR"
fi

# 11. cleanup
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

if [ "$SSH_ACCEPTED" == "$1" ]; then
    echo "-- ssh key created --"
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
    JAVA_VERSION="$(javac -version | cut -d ' ' -f 2)"
    SCALA_VERSION="$(scalac -version | cut -d ' ' -f 4)"
    echo "-- java $JAVA_VERSION installed, scala $SCALA_VERSION installed, maven installed --"
fi

if [ "$GO_ACCEPTED" == "1" ]; then
    GO_VERSION="$(go version | cut -d ' ' -f 3 | cut -d o -f 2)"
    echo "-- go $GO_VERSION installed & configured in ~/.go --"
fi

if [ "$NODE_ACCEPTED" == "1" ]; then
    NODE_VERSION="$(node -v)"
    echo "-- node.js $NODE_VERSION installed & configured in ~/.nvm --"
fi

if [ "$PHP_ACCEPTED" == "1" ]; then
    PHP_VERSION="$(php -v | sed -n 1p | cut -d ' ' -f 2)"
    echo "-- php $PHP_VERSION installed & composer installed"
fi

if [ "$RUST_ACCEPTED" == "1" ]; then
    RUST_VERSION="$(rustc -V | cut -d ' ' -f 2 | tr -d '[:space:]')"
    echo "-- rust $RUST_VERSION & and cargo package manager installed --"
fi

echo -e "\n\nall done! \nplease leave feedback: \n$ISSUES_URL"

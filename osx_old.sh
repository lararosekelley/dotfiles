# osx
# ------------------------

# bootstraps an apple computer for development work

# table of contents
# ------------------------
# 0. intro & helper functions
# 1. xcode
# 2. homebrew
# 3. brew cask
# 4. atom
# 5. vim
# 6. node
# 7. python
# 8. ruby
# 9. dotfiles
# 10. checklist for user
# ------------------------

# 1. global variables
# --------

LOG_LEVELS=(info warning fatal)
REPO_URL="https://github.com/tylucaskelley/osx/tarball/master"
MIN_VERSION="10.11"
INSTALL_DIR="~/.osx"

# 2. get repo
# --------

curl -sL ${REPO_URL} | tar zx -C ~/.osx

############
# 0. intro #
############

echo "welcome to the osx setup script! this script will guide you through your development environment setup."

# get sudo permission for duration of script

echo "\nplease enter your password: "

sudo -v

while true; do
    sudo -n true
    sleep 60
    kill -0 "$$" || exit
done 2>/dev/null &

# check mac version

OS_VERSION=$(sw_vers -productVersion | awk -F '.' '{print $1 "." $2}')

if [ "$OS_VERSION" != "$MIN_VERSION" ]; then
    echo "${LOG_LEVELS[2]}: osx ${MIN_VERSION} required; current version is ${OS_VERSION}"
    exit 1
fi

echo "good to go!\n"

# helper functions

function brew_installed() {
    if [[ $(brew ls --versions $1) ]]; then
        return true
    fi

    return false
}

function brew_install_upgrade() {
    if brew_installed "$1"; then
        brew upgrade "$1"
    else
        brew install "$1"
    fi
}

function gem_install_upgrade() {

}

function pip_install_upgrade() {

}

function npm_install_upgrade() {

}

function apm_install_upgrade() {

}

function ask_yes_no() {
    read -p "${LOG_LEVELS[0]}: $1" -n 1
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        return true
    fi

    return false
}

############
# 1. xcode #
############

echo "1. xcode"

xcode-select -p >&-

if [ "$?" != "0" ]; then
    read -p "${LOG_LEVELS[0]}: xcode command line tools not installed; install them? (y/n) " -n 1
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        xcode-select --install
        echo "${LOG_LEVELS[0]}: please re-run script after xcode install is finished"
    fi
fi

###############
# 2. homebrew #
###############

echo "2. homebrew"

# install brew

brew help >&-

if [ "$?" != "0" ]; then
    read -p "${LOG_LEVELS[0]}: homebrew not installed; install it? (y/n) " -n 1
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" >&-
    fi
fi

# install packages

read -p "${LOG_LEVELS[0]}: install homebrew packages? (y/n) " -n 1
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    source ${INSTALL_DIR}/scripts/brew.sh
fi

################
# 3. brew cask #
################

echo "3. brew cask"

read -p "${LOG_LEVELS[0]}: install programs with brew cask? (y/n) " -n 1
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    source ${INSTALL_DIR}/scripts/brew-cask.sh
fi

###########
# 4. atom #
###########

echo "4. atom"

apm list >&-

if [ "$?" != "0" ]; then
    read -p "${LOG_LEVELS[0]}: install atom packages? (y/n) " -n 1
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        source ${INSTALL_DIR}

read -d '' exit_msg << EOF
***********************************************
**    all done!                              **
**                                           **
**    please leave feedback:                 **
**    github.com/tylucaskelley/osx/issues    **
***********************************************
EOF

echo "\n\n$exit_msg\n\n"

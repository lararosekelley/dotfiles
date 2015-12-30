# osx
# ------------------------

# bootstraps an apple computer for development work

# table of contents
# ------------------------
# 1. global variables
# 2. setup
# 3. xcode
# 4. homebrew
# 5. brew cask
# ------------------------

# 1. global variables
# --------

OS_VERSION=$(sw_vers -productVersion | awk -F '.' '{print $1 "." $2}')
MIN_VERSION="10.11"

REPO_URL="https://github.com/tylucaskelley/osx/tarball/master"
INSTALL_DIR="${HOME}/.osx"

# 2. setup
# --------

# check os version

if [ "$OS_VERSION" != "$MIN_VERSION" ]; then
    echo "error: osx ${MIN_VERSION} required; current version is ${OS_VERSION}"
    exit 1
fi

echo "setting up osx development environment..."

# get sudo priveleges for whole script

echo "please enter your password: "

sudo -v

while true; do
    sudo -n true
    sleep 60
    kill -0 "$$" || exit
done 2>/dev/null &

# save git repo to ~/.osx

read -p "create ~/.osx directory? (will delete existing files) (y/n) " -n 1
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf ~/.osx && mkdir ~/.osx
    curl -sL ${REPO_URL} | tar zx -C ~/.osx --strip-components 1
else
    echo "error: setup cannot continue without ~/.osx directory"
    exit 1
fi


# source helper & package list files

source ${INSTALL_DIR}/scripts/helpers.sh
source ${INSTALL_DIR}/scripts/packages.sh

# 3. xcode
# --------

xcode-select -p &> /dev/null

if [ "$?" != "0" ]; then
    prompt_user "install xcode command line tools? (y/n)"

    if [ "$?" == "0" ]; then
        echo "installing xcode command line tools..."
        touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
        XCODE=$(softwareupdate -l | grep "\*.*Command Line" | head -n 1 | awk -F"*" '{print $2}' | sed -e 's/^ *//' | tr -d '\n')
        softwareupdate -i "$XCODE"
        rm /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
    else
        echo "error: setup cannot continue without xcode command line tools"
        exit 1
    fi
fi

# 4. homebrew
# --------

brew help &> /dev/null

if [ "$?" != "0" ]; then
    prompt_user "install homebrew? (y/n)"

    if [ "$?" == "0" ]; then
        echo "installing homebrew..."
        ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    else
        echo "error: setup cannot continue without homebrew"
        exit 1
    fi
fi

prompt_user "install and upgrade homebrew packages? (y/n)"

if [ "$?" == "0" ]; then
    echo "installing homebrew packages..."

    brew update
    brew upgrade --all

    brew tap homebrew/dupes
    brew tap caskroom/cask

    brew install ${BREW_PACKAGES[@]}

    brew cleanup

    # go
    mkdir -p ~/.go

    # mongodb
    sudo mkdir -p /data/db && sudo chmod 777 /data/db
else
    echo "error: setup cannot continue without homebrew packages"
    exit 1
fi

# 5. brew cask
# --------

prompt_user "install mac apps with brew cask? (y/n)"

if [ "$?" == "0" ]; then
    echo "installing mac apps with brew cask..."

    brew cask install ${BREW_CASK_PACKAGES[@]}

    brew cask cleanup
fi

# 6. dotfiles
# --------

prompt_user "create dotfiles? (y/n)"

if [ "$?" == "0" ]; then
    echo "copying over dotfiles..."

    cp -a ~/.osx/dotfiles/. ~
else
    echo "error: setup cannot continue without dotfiles"
    exit 1
fi
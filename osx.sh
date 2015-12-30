# osx
# --------

# bootstraps an apple computer for development work

# table of contents
# --------
# 1. global variables
# 2. setup
# 3. xcode
# 4. homebrew
# 5. brew cask
# 6. dotfiles & terminal theme
# 7. vim
# --------

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

# 6. dotfiles & terminal theme
# --------

prompt_user "create dotfiles? (y/n)"

if [ "$?" == "0" ]; then
    echo "copying over dotfiles..."

    cp -a ~/.osx/dotfiles/. ~
else
    echo "error: setup cannot continue without dotfiles"
    exit 1
fi

# create user-specific environment file

prompt_user "configure ~/.env environment file (git username, etc.)? (y/n)"

if [ "$?" == "0" ]; then
    echo "creating ~/.env file..."

    rm ~/.env && touch ~/.env

    echo -n "Enter your name and press [ENTER]: "
    read user_name

    echo -n "Enter your email address and press [ENTER]: "
    read user_email

    # copy to file

    echo "# env" >> ~/.env
    echo "# --------" >> ~/.env
    echo "\n# git credentials\n" >> ~/.env
    echo "GIT_AUTHOR_NAME=\"${user_name}\"" >> ~/.env
    echo "GIT_AUTHOR_EMAIL=\"${user_email}\"" >> ~/.env
    echo "GIT_COMMITTER_NAME=\"${user_name}\"" >> ~/.env
    echo "GIT_COMMITTER_EMAIL=\"${user_email}\"" >> ~/.env
    echo "git config --global user.name \"${user_name}\"" >> ~/.env
    echo "git config --global user.email \"${user_email}\"" >> ~/.env
fi

# terminal theme

prompt_user "change your terminal theme? (y/n)"

if [ "$?" == "0" ]; then
    echo "changing terminal theme..."

    curl -o ~/Library/Preferences/com.apple.Terminal.plist https://github.com/tylucaskelley/osx/blob/master/themes/com.apple.Terminal.plist && defaults read com.apple.Terminal
fi

# 7. vim
# --------

prompt_user "set up vim? (y/n)"

if [ "$?" == "0" ]; then
    echo "setting up vim..."

    
fi

# download theme

# get pathogen

# download packages



# 8. python
# --------

# 9. ruby
# --------

# 10. node
# --------

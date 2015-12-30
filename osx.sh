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
# 8. python
# 9. node
# 10. ruby
# 11. atom
# --------

# 1. global variables
# --------

OS_VERSION=$(sw_vers -productVersion | awk -F '.' '{print $1 "." $2}')
MIN_VERSION="10.11"
REPO_URL="https://github.com/tylucaskelley/osx/tarball/master"
RUBY_VERSION="2.2.4"

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

source ~/.osx/scripts/helpers.sh
source ~/.osx/scripts/packages.sh

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

    # node.js
    n stable

    # ruby
    rbenv install ${RUBY_VERSION}
    rbenv global ${RUBY_VERSION}

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

    touch ~/.env

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

    cp ~/.osx/themes/com.apple.Terminal.plist ~/Library/Preferences/com.apple.Terminal.plist
    defaults read com.apple.Terminal
fi

# 7. vim
# --------

prompt_user "set up vim? (y/n)"

if [ "$?" == "0" ]; then
    echo "setting up vim..."

    # download theme

    mkdir -p ~/.vim/colors
    cp ~/.osx/themes/Tomorrow-Night.vim ~/.vim/colors

    # get pathogen

    mkdir -p ~/.vim/autoload && mkdir -p ~/.vim/bundle
    cp ~/.osx/pathogen.vim ~/.vim/autoload

    # download packages

    cd ~/.vim/bundle
    git clone ${VIM_PACKAGES[@]}
    cd ~

    # backup & swap directories

    mkdir -p ~/.vim/swaps ~/.vim/backups
fi

# 8. python
# --------

prompt_user "install python 2 packages with pip? (y/n)"

if [ "$?" == "0" ]; then
    echo "installing python 2 packages..."

    pip install ${PIP_PACKAGES[@]}
fi

# 9. node
# --------

prompt_user "install node.js packages with npm? (y/n)"

if [ "$?" == "0" ]; then
    echo "installing node.js packages..."

    npm install -g ${NODE_PACKAGES[@]}
fi

# 10. ruby
# --------

prompt_user "install ruby gems? (y/n)"

if [ "$?" == "0" ]; then
    echo "installing ruby gems..."

    gem install ${RUBY_PACKAGES[@]}
fi

# 11. atom
# --------

prompt_user "set up github's atom text editor? (y/n)"

if [ "$?" == "0" ]; then
    echo "setting up atom..."

    mkdir -p ~/.atom

    apm install ${ATOM_PACKAGES[@]}

    cp ~/.osx/config.cson ~/.atom/config.cson
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

#!/usr/bin/env bash

# brew
# --------

# installs command line utilities via homebrew

TOOLS=(
    ack
    app-engine-python
    autojump
    bash
    bash-completion
    binutils
    cmake
    diffutils
    docker
    docker-machine
    emacs
    findutils
    flac
    ffmpeg
    gawk
    gdb
    gifsicle
    git
    gnu-indent
    gnu-sed
    gnu-tar
    gnu-which
    gnutls
    gradle
    grep
    gzip
    httpie
    icdiff
    jq
    lame
    less
    libffi
    libxml2
    make
    mercurial
    nano
    openssl
    reattach-to-user-namespace
    shellcheck
    sl
    tmux
    tree
    valgrind
    "vim --with-lua --override-system-vi"
    watch
    wdiff
    wget
    xz
)

DATABASES=(
    memcached
    mongodb
    mysql
    postgresql
    redis
    sqlite
)

log -v "setting up homebrew..."

brew update &> /dev/null
brew upgrade --all &> /dev/null

brew tap caskroom/cask &> /dev/null
brew tap caskroom/fonts &> /dev/null
brew tap caskroom/versions &> /dev/null
brew tap homebrew/binary &> /dev/null
brew tap homebrew/boneyard &> /dev/null
brew tap homebrew/bundle &> /dev/null
brew tap homebrew/core &> /dev/null
brew tap homebrew/dupes &> /dev/null
brew tap homebrew/services &> /dev/null
brew tap homebrew/versions &> /dev/null

log -v "installing command line tools & utilities..."

for t in "${TOOLS[@]}"; do
    brew_install "$t"
done

log -v "installing databases..."

for d in "${DATABASES[@]}"; do
    prompt_user "install $d?"

    if [ $? == "0" ]; then
        brew_install "$d"
    fi
done

log -v "brew prune & cleanup..."

brew cleanup &> /dev/null
brew prune &> /dev/null

log -v "changing shell..."

# bash setup

chsh -s /usr/local/bin/bash

if [ "$?" != "0" ]; then
    echo "/usr/local/bin/bash" | sudo tee -a /etc/shells
    chsh -s /usr/local/bin/bash
fi

#!/usr/bin/env bash

# brew
#
# installs command line utilities via homebrew
# --------

TOOLS=(
    ack
    aspell
    autojump
    bash
    bash-completion
    binutils
    binwalk
    cmake
    coreutils
    diffutils
    djvu2pdf
    docker
    docker-machine
    doxygen
    emacs
    findutils
    flac
    ffmpeg
    fswatch
    gdb
    gifsicle
    git
    gnu-indent
    gnu-sed
    gnu-tar
    gnu-which
    gnutls
    grep
    gzip
    httpie
    hydra
    icdiff
    jq
    lame
    less
    lynx
    make
    mercurial
    nano
    nmap
    openssl
    pandoc
    php56
    python
    python3
    reattach-to-user-namespace
    shellcheck
    sl
    tmux
    tree
    valgrind
    watch
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

brew update && brew upgrade

brew tap caskroom/cask
brew tap caskroom/fonts
brew tap caskroom/versions
brew tap homebrew/binary
brew tap homebrew/boneyard
brew tap homebrew/bundle
brew tap homebrew/dupes
brew tap homebrew/services
brew tap homebrew/php
brew tap homebrew/versions

log -v "installing command line tools & utilities..."

for t in "${TOOLS[@]}"; do
    brew_install "$t"
done

log -v "installing databases..."

for d in "${DATABASES[@]}"; do
    if prompt_user "install $d?"; then
        brew_install "$d"
    fi
done

log -v "brew prune & cleanup..."

brew cleanup
brew prune

log -v "changing shell... you will be prompted for your password"

# bash setup

if ! chsh -s /usr/local/bin/bash; then
    echo "/usr/local/bin/bash" | sudo tee -a /etc/shells
    chsh -s /usr/local/bin/bash
fi

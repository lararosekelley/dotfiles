#!/usr/bin/env bash

# brew
# --------

# installs command line utilities via homebrew

TOOLS=(
    ack
    autojump
    bash
    bash-completion
    binutils
    cmake
    diffutils
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
    jq
    lame
    less
    libffi
    libxml2
    make
    mercurial
    nano
    openssh
    shellcheck
    sl
    tmux
    tree
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
    sqllite
)

log -v "setting up homebrew..."

brew update &> /dev/null
brew upgrade --all &> /dev/null

caskroom/cask &> /dev/null
caskroom/versions &> /dev/null
homebrew/binary &> /dev/null
homebrew/boneyard &> /dev/null
homebrew/bundle &> /dev/null
homebrew/core &> /dev/null
homebrew/dupes &> /dev/null
homebrew/services &> /dev/null
homebrew/versions &> /dev/null

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

#!/usr/bin/env bash

BREW_PACKAGES=(
    coreutils # gnu stuff
    binutils
    diffutils
    ed --with-default-names
    findutils --with-default-names
    gawk
    gdb
    gnu-indent --with-default-names
    gnu-sed --with-default-names
    gnu-tar --with-default-names
    gnu-which --with-default-names
    gnutls
    grep --with-default-names
    gzip
    screen
    watch
    wdiff --with-gettext
    wget --with-iri
    bash # upgrade osx stuff
    emacs
    vim --override-system-vi --with-lua
    make
    nano
    git
    less
    mercurial
    openssh
    screen
    tmux
    svn
    rsync
    unzip
    go # languages and frameworks
    python
    python3
    n
    rbenv
    ruby-build
    gradle
    mongodb # databases
    mysql
    postgresql
    sqlite
    ack # other tools
    autojump
    curl
    ffmpeg
    gifsicle
    jq
    libffi
    libxml2
    lynx
    ngrok
    sl
    tree
    xz
)

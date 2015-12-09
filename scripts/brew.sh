#!/usr/bin/env bash
# installs brew packages

packages=(
    ack
    autoconf
    autojump
    caskroom/cask/brew-cask
    curl
    emacs
    ffmpeg
    gdbm
    gifsicle
    git
    go
    go-app-engine-64
    gradle
    heroku-toolbelt
    hugo
    jq
    libevent
    libffi
    libxml2
    lua
    lynx
    mercurial
    mongodb
    mysql
    n
    ngrok
    openssl
    pkg-config
    postgresql
    python
    python3
    rbenv
    readline
    ruby-build
    sl
    sqlite
    tmux
    tree
    vim --override-system-vi --with-lua
    wget
    xz
)

if [ -x /usr/local/bin/brew ]; then
    brew update && brew upgrade && brew cleanup && brew install ${packages[@]};
else
    echo "brew not installed to /usr/local/bin/brew... aborting";
fi

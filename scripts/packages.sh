#!/usr/bin/env bash

# package lists
# --------

ATOM_PACKAGES=(
    atom-ternjs
    autoclose-html
    autocomplete-paths
    color-picker
    file-icons
    git-plus
    language-batch
    language-gradle
    language-jade
    language-tmux
    language-viml
    linter
    linter-csslint
    linter-htmlhint
    linter-jshint
    linter-pep8
    merge-conflicts
    minimap
    pdf-view
    pigments
    travis-ci-status
)

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

BREW_CASK_PACKAGES=(
    appcleaner
    atom
    firefox
    google-chrome
    java
    paw
    sketch
    slack
    steam
    the-unarchiver
    utorrent
    vagrant
    virtualbox
    xquartz
)

NODE_PACKAGES=(
    bower
    csslint
    gulp
    htmlhint
    http-server
    jshint
    npm-check-updates
    yo
)

PIP_PACKAGES=(
    closure-linter
    ipython
    licenser
    pep8
    uncommitted
    virtualenv
)

RUBY_PACKAGES=(
    jekyll
    rails
    sass
    sinatra
)

VIM_PACKAGES=(
    https://github.com/kien/ctrlp.vim.git
    https://github.com/scrooloose/syntastic.git
    https://github.com/bling/vim-airline.git
)

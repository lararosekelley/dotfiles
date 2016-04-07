#!/usr/bin/env bash

# package lists
# --------

ATOM_PACKAGES=(
    atom-ternjs
    autoclose-html
    autocomplete-python
    color-picker
    editorconfig
    file-icons
    highlight-line
    language-batch
    language-gradle
    language-jade
    language-javascript-jsx
    language-tmux
    language-viml
    linter
    linter-csslint
    linter-golinter
    linter-handlebars
    linter-htmlhint
    linter-jshint
    linter-pep8
    linter-ruby
    linter-sass-lint
    linter-shellcheck
    minimap
    pdf-view
    pigments
    terminal-plus
    todo-show
    travis-ci-status
)

BREW_PACKAGES=(
    coreutils # gnu stuff
    cmake
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
    watch
    wdiff --with-gettext
    wget --with-iri
    bash # upgrade osx stuff
    bash-completion
    emacs
    vim --override-system-vi --with-lua
    make
    nano
    lame
    flac
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
    nvm
    rbenv
    ruby-build
    gradle
    mongodb # databases
    memcached
    mysql
    postgresql
    redis
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
    shellcheck
    sl
    tree
    xz
)

BREW_CASK_PACKAGES=(
    appcleaner
    atom
    firefox
    github-desktop
    google-chrome
    googleappengine
    java
    paw
    sketch
    slack
    the-unarchiver
    utorrent
    vagrant
    virtualbox
    vlc
    xquartz
)

NODE_PACKAGES=(
    bower
    csslint
    gulp
    htmlhint
    http-server
    jshint
    nodemon
    npm-check-updates
    pm2
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

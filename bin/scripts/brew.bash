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
    openssh
    shellcheck
    sl
    tmux
    tree
    watch
    "wdiff --with-gettext"
    "wget --with-iri"
    xz
)

TEXT_EDITORS=(
    ed
    emacs
    "vim --with-lua --override-system-vi"
    nano
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
    brew_install $t
done

# handle caveats for each tool installed



log -v "installing text editors..."

for e in "${TEXT_EDITORS[@]}"; do
    prompt_user "install $e?"

    if [ $? == "0" ]; then
        brew_install $e
    fi
done

log -v "installing databases..."

for d in "${DATABASES[@]}"; do
    prompt_user "install $d?"

    if [ $? == "0" ]; then
        brew_install $d
    fi
done

brew cleanup &> /dev/null

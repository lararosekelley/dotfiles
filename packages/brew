#!/usr/bin/env sh

# brew
# installs a bunch of brew formulas
# all logging sent to ~/start-debug.log

# all packages, except those that require special flags
PKGS="node python python3 go mongodb postgresql mysql ack jq wget tree lynx emacs \
    heroku-toolbelt google-app-engine app-engine-java-sdk brew-cask"

chk_status() {
    eval "$1"
    return $?
}

say() {
    local GREEN='\033[1;32m'
    local NO_COLOR='\033[0m'
    echo $GREEN$1$NO_COLOR
}

err() {
    local RED="\033[1;31m"
    local NO_COLOR="\033[0m"
    echo >&2 $RED$1$NO_COLOR
}

echo "\n*************\nbrew\n$(date)\n*************\n"  >> ~/start-debug.log

sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

if (command -v brew >/dev/null 2>&1); then
    echo "\ninstalling brew formulas..."
    brew update >> ~/start-debug.log
    brew upgrade >> ~/start-debug.log

    for i in $PKGS; do
        if chk_status "brew install $i >> ~/start-debug.log 2>&1"; then
            say "\t$i: installed"
        else
            err "\t$i: failed"
        fi
    done

    # vim
    if chk_status "brew install vim --override-system-vi >> ~/start-debug.log 2>&1"; then
        say "\tvim: installed"
    else
        err "\tvim: failed"
    fi

    # rbenv

    brew cleanup >> ~/start-debug.log
    echo "done! see ~/start-debug.log for details.\n"
else
    err "\nerror: brew not installed! aborting...\n" && exit 1
fi

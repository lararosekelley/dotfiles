#!/usr/bin/env sh

# npm
# installs a bunch of npm packages
# all logging sent to ~/start-debug.log

PKGS="yo bower jshint csslint htmlhint http-server grunt-cli mocha"

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

echo "\n*************\nnpm\n$(date)\n*************\n"  >> ~/start-debug.log

if (command -v npm >/dev/null 2>&1); then
    echo "\ninstalling node modules..."

    for i in $PKGS; do
        if chk_status "npm install -g $i >> ~/start-debug.log 2>&1"; then
            say "\t$i: installed"
        else
            err "\t$i: failed"
        fi
    done

    echo "done! see ~/start-debug.log for details.\n"
else
    err "\nerror: npm not installed! aborting...\n" && exit 1
fi

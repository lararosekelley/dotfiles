#!/usr/bin/env sh

# pip
# installs a bunch of pip packages
# all logging sent to ~/start-debug.log

PKGS="ipython licenser pep8 requests virtualenv Pillow Scrapy numpy"

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

echo "\n*************\npip\n$(date)\n*************\n" >> ~/start-debug.log

if (command -v pip >/dev/null 2>&1); then
    echo "\ninstalling python packages..."

    for i in $PKGS; do
        if chk_status "pip install $i >> ~/start-debug.log 2>&1"; then
            say "\t$i: installed"
        else
            err "\t$i: failed"
        fi
    done

    echo "done! see ~/start-debug.log for details.\n"
else
    err "\nerror: pip not installed! aborting...\n" && exit 1
fi

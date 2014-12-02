#!/usr/bin/env sh

# atom
# installs a bunch of atom packages
# all logging sent to ~/start-debug.log

PKGS="autocomplete-paths autocomplete-plus color-picker file-icons highlight-line \
    language-jade linter linter-csslint linter-htmlhint linter-jshint linter-pep8 \
    minimap monokai seti-syntax seti-ui travis-ci-status"

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

echo "\n*************\natom\n$(date)\n*************\n" >> ~/start-debug.log

if (command -v apm >/dev/null 2>&1); then
    echo "\ninstalling atom packages..."

    for i in $PKGS; do
        if chk_status "apm install $i >> ~/start-debug.log 2>&1"; then
            say "\t$i: installed"
        else
            err "\t$i: failed"
        fi
    done

    echo "done! see ~/start-debug.log for details.\n"
else
    err "\nerror: atom not installed! aborting...\n" && exit 1
fi

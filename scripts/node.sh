#!/usr/bin/env bash
# installs node libraries

packages=(
    bower
    csslint
    gulp
    htmlhint
    http-server
    jshint
    npm-check-updates
    yo
)

if [ -x /usr/local/bin/npm ]; then
    npm install -g ${packages[@]};
else
    echo "npm not installed to /usr/local/bin... aborting";
fi

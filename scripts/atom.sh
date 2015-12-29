#!/usr/bin/env bash

# make .atom directory

mkdir -p ~/.atom

# install packages

apm install atom-ternjs
apm install autoclose-html
apm install autocomplete-paths
apm install color-picker
apm install file-icons
apm install git-plus
apm install language-batch
apm install language-gradle
apm install language-jade
apm install language-tmux
apm install language-viml
apm install linter
apm install linter-csslint
apm install linter-htmlhint
apm install linter-jshint
apm install linter-pep8
apm install merge-conflicts
apm install minimap
apm install pdf-view
apm install pigments
apm install travis-ci-status

# copy config.cson

curl https://raw.githubusercontent.com/tylucaskelley/osx/master/config.cson -o ~/.atom/config.cson

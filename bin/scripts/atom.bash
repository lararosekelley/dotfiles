#!/usr/bin/env bash

# atom
# --------

# configures the atom editor

PACKAGES=(
    autoclose-html
    color-picker
    editorconfig
    file-icons
    highlight-line
    language-batch
    language-gradle
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
    travis-ci-status
)

log -v "installing & configuring atom..."

brew cask install atom

if [ -d ~/.atom ]; then
    rm -rf ~/.atom
fi

mkdir -p ~/.atom

cp $1/bin/themes/config.cson ~/.atom/config.cson

for p in "${PACKAGES[@]}"; do
    apm install "$p"
done

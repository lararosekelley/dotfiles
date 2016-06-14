#!/usr/bin/env bash

# atom
# --------

# configures the atom editor

PACKAGES=(
    autoclose-html
    atom-ternjs
    autocomplete-python
    color-picker
    editorconfig
    file-icons
    git-time-machine
    highlight-line
    language-batch
    language-gradle
    language-tmux
    language-viml
    linter
    linter-csslint
    linter-eslint
    linter-golinter
    linter-handlebars
    linter-htmlhint
    linter-pep8
    linter-ruby
    linter-sass-lint
    linter-shellcheck
    minimap
    node-debugger
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

cp "$1"/bin/themes/config.cson ~/.atom/config.cson

for p in "${PACKAGES[@]}"; do
    apm install "$p"
done

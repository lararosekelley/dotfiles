#!/usr/bin/env bash
# installs atom packages

packages=(
    atom-ternjs
    autoclose-html
    autocomplete-paths
    color-picker
    file-icons
    git-plus
    language-batch
    language-gradle
    language-jade
    language-viml
    linter
    linter-csslint
    linter-htmlhint
    linter-jshint
    linter-pep8
    merge-conflicts
    minimap
    pigments
    travis-ci-status
)

if [ -x /usr/local/bin/apm ]; then
    apm install ${packages[@]}
else
    echo "apm not installed to /usr/local/bin... aborting";
fi

#!/usr/bin/env bash
# installs python 2 libraries

packages=(
    closure-linter
    ipython
    licenser
    pep8
    uncommitted
    virtualenv
)

if [ -x /usr/local/bin/pip ]; then
    pip install ${packages[@]};
else
    echo "pip not installed to /usr/local/bin... aborting";
fi

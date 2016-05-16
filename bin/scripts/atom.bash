#!/usr/bin/env bash

# atom
# --------

# configures the atom editor

if [ -d ~/.atom ]; then
    rm -rf ~/.atom
fi

mkdir -p ~/.atom

cp $1/

#!/usr/bin/env bash

# go
# --------

# sets up go environment

PACKAGES=(
    github.com/golang/lint/golint
)

log -v "setting up go..."

brew_install go
mkdir -p ~/.go

for p in "${PACKAGES[@]}"; do
    go get "$p"
done

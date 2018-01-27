#!/usr/bin/env bash

# rust
#
# sets up rust environment
# --------

PACKAGES=(
    rustfmt
)

brew_install rust
mkdir -p ~/.cargo

for p in "${PACKAGES[@]}"; do
    if prompt_user "install $p? (y/n)"; then
        cargo install "$p"
    fi
done

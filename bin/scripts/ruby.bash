#!/usr/bin/env bash

# ruby
#
# sets up ruby environment
# --------

PACKAGES=(
    bundler
    jekyll
    mdl
    rails
    sass
    sinatra
    sqlint
)

log -v "setting up ruby..."

brew_install rbenv
brew_install ruby-build
eval "$(rbenv init -)"

rbenv rehash

RUBY_VERSION="$(rbenv install -l | grep -v - | tail -1 | tr -d '[:space:]')"

rbenv install "$RUBY_VERSION"
rbenv global "$RUBY_VERSION"

# need to do this again for some reason

eval "$(rbenv init -)"

for p in "${PACKAGES[@]}"; do
    if prompt_user "install $p? (y/n)"; then
        gem install "$p"
    fi
done

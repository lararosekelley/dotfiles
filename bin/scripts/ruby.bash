#!/usr/bin/env bash

# ruby
#
# sets up ruby environment
# --------

PACKAGES=(
    bundler
    jekyll
    rails
    sass
    sinatra
)

log -v "setting up ruby..."

brew_install rbenv
brew_install ruby-build
eval "$(rbenv init -)"

rbenv rehash

RUBY_VERSION="$(rbenv install -l | grep -v - | tail -1 | tr -d '[:space:]')"

rbenv install "$RUBY_VERSION"
rbenv global "$RUBY_VERSION"

for p in "${PACKAGES[@]}"; do
    gem install "$p"
done

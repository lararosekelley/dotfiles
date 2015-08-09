#!/usr/bin/env bash
# installs ruby gems

packages=(
    jekyll
    rails
    sass
    sinatra
)

if [ -x /usr/local/var/rbenv/shims/gem ]; then
    gem install ${packages[@]};
else
    echo "ruby not installed via rbenv... aborting";
fi

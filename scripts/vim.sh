#!/usr/bin/env bash
# installs brew cask packages

packages=(
    git@github.com:kien/ctrlp.vim.git
    git@github.com:ervandew/supertab.git
    git@github.com:scrooloose/syntastic.git
    git@github.com:altercation/vim-colors-solarized.git
    git@github.com:bling/vim-airline.git
    git@github.com:scrooloose/nerdtree.git
)

if [ -x /usr/local/bin/git ] && [ -d ~/.vim/bundle ]; then
    dir=pwd
    cd ~/.vim/bundle

    for repo in ${packages[@]}; do
        git clone $repo
    done

    cd dir
else
    echo "git not installed to /usr/local/bin or ~/.vim/bundle does not exist... aborting";
fi

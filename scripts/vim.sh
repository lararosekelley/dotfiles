#!/usr/bin/env bash
# installs vim packages

packages=(
    https://github.com/kien/ctrlp.vim.git
    https://github.com/scrooloose/syntastic.git
    https://github.com/bling/vim-airline.git
)

if [ -x /usr/local/bin/git ] && [ -d ~/.vim/bundle ]; then
    cd ~/.vim/bundle

    for repo in ${packages[@]}; do
        git clone $repo
    done

    cd ~
else
    echo "git not installed to /usr/local/bin or ~/.vim/bundle does not exist... aborting";
fi

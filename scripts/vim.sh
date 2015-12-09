#!/usr/bin/env bash
# installs vim packages

packages=(
    https://github.com/kien/ctrlp.vim.git
    https://github.com/ervandew/supertab.git
    https://github.com/scrooloose/syntastic.git
    https://github.com/altercation/vim-colors-solarized.git
    https://github.com/bling/vim-airline.git
    https://github.com/scrooloose/nerdtree.git
)

if [ -x /usr/local/bin/git ] && [ -d ~/.vim/bundle ]; then
    dir=pwd
    cd ~/.vim/bundle

    for repo in ${packages[@]}; do
        git clone $repo
    done

    cd $dir
else
    echo "git not installed to /usr/local/bin or ~/.vim/bundle does not exist... aborting";
fi

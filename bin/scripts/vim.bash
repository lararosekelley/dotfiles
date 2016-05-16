#!/usr/bin/env bash

# vim
# --------

# sets up the vim editor for development work

PACKAGES=(
    https://github.com/kien/ctrlp.vim.git
    https://github.com/scrooloose/syntastic.git
    https://github.com/bling/vim-airline.git
)

log -v "configuring vim..."

if [ -d ~/.vim ]; then
    rm -rf ~/.vim
fi

mkdir -p ~/.vim/colors
cp "$1"/bin/themes/Tomorrow-Night.vim ~/.vim/colors

mkdir -p ~/.vim/autoload && mkdir -p ~/.vim/bundle
curl -LSso ~/.vim/autoload/pathogen.vim https://raw.githubusercontent.com/tpope/vim-pathogen/master/autoload/pathogen.vim

cd ~/.vim/bundle || exit

for repo in "${PACKAGES[@]}"; do
    git clone "$repo"
done

cd ~ || exit

mkdir -p ~/.vim/swaps ~/.vim/backups

cp "$1"/bin/dotfiles/.vimrc ~/.vimrc

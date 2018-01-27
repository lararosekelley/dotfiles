#!/usr/bin/env bash

# vim
#
# sets up the vim editor for development work
# --------

log -v "configuring vim..."

brew install vim --with-lua --with-override-system-vi

if [ -d ~/.vim ]; then
    rm -rf ~/.vim
fi

# install vim-plug

curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# copy .vimrc

cp "$1"/bin/dotfiles/.vimrc ~/.vimrc

# copy vim snippets

mkdir -p ~/.vim/snips
cp -R "$1"/bin/lib/vim/snips ~/.vim

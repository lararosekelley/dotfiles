#!/usr/bin/env bash

# vim
#
# sets up the vim editor for development work
# --------

PACKAGES=(
    https://github.com/Valloric/YouCompleteMe.git
    https://github.com/Raimondi/delimitMate.git
    https://github.com/scrooloose/syntastic.git
    https://github.com/vim-airline/vim-airline-themes.git
    https://github.com/vim-airline/vim-airline.git
    https://github.com/airblade/vim-gitgutter.git
    https://github.com/ctrlpvim/ctrlp.vim.git
    https://github.com/tpope/vim-fugitive.git
    https://github.com/pangloss/vim-javascript.git
    https://github.com/lilydjwg/colorizer.git
    https://github.com/mustache/vim-mustache-handlebars.git
    https://github.com/posva/vim-vue.git
    https://github.com/yggdroot/indentline.git
    https://github.com/editorconfig/editorconfig-vim.git
    https://github.com/lervag/vimtex.git
)

log -v "configuring vim..."

brew install vim --with-lua --with-client-server --with-override-system-vi

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

# set up YouCompleteMe

cd YouCompleteMe || exit
git submodule update --init --recursive

# must use python with framework enabled

/usr/bin/python install.py --clang-completer

cd ~ || exit

mkdir -p ~/.vim/swaps ~/.vim/backups ~/.vim/after/ftplugin

cp "$1"/bin/dotfiles/.vimrc ~/.vimrc

# add file to ~/.vim/after to allow use of locally installed eslint over global

touch ~/.vim/after/ftplugin/javascript.vim

cat > ~/.vim/after/ftplugin/javascript.vim << EOL
let s:eslint_path = system('PATH=$(npm bin --silent):$PATH && which eslint')
let b:syntastic_javascript_eslint_exec = StrTrim(s:eslint_path)
EOL

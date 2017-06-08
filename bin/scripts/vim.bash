#!/usr/bin/env bash

# vim
#
# sets up the vim editor for development work
# --------

PACKAGES=(

)

log -v "configuring vim..."

# xquartz needed for client-server mode

if [ ! -d /usr/local/Caskroom/xquartz ]; then
    brew cask install xquartz
fi

brew install vim --with-lua --with-client-server --with-override-system-vi

if [ -d ~/.vim ]; then
    rm -rf ~/.vim
fi

mkdir -p ~/.vim/autoload && mkdir -p ~/.vim/bundle
curl -LSso ~/.vim/autoload/pathogen.vim https://raw.githubusercontent.com/tpope/vim-pathogen/master/autoload/pathogen.vim

cd ~/.vim/bundle || exit

for repo in "${PACKAGES[@]}"; do
    git clone "$repo"
done

# move all vim themes to colors directory

mkdir -p ~/.vim/colors
cp -R ~/.vim/bundle/vim-colorschemes/colors/ ~/.vim/bundle/colors/

cd ~ || exit

mkdir -p ~/.vim/swaps ~/.vim/backups ~/.vim/after/ftplugin

cp "$1"/bin/dotfiles/.vimrc ~/.vimrc

# set up youcompleteme

cd ~/.vim/bundle/YouCompleteMe || exit
git submodule update --init --recursive
/usr/bin/python install.py --clang-completer

# add file to ~/.vim/after to allow use of locally installed eslint over global

touch ~/.vim/after/ftplugin/javascript.vim

cat > ~/.vim/after/ftplugin/javascript.vim << EOL
let s:eslint_path = system('PATH=$(npm bin --silent):$PATH && which eslint')
let b:syntastic_javascript_eslint_exec = StrTrim(s:eslint_path)
EOL

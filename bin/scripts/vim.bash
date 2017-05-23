#!/usr/bin/env bash

# vim
#
# sets up the vim editor for development work
# --------

PACKAGES=(
    https://github.com/valloric/MatchTagAlways
    https://github.com/lilydjwg/colorizer
    https://github.com/chrisbra/csv.vim
    https://github.com/ctrlpvim/ctrlp.vim
    https://github.com/rizzatti/dash.vim
    https://github.com/vim-scripts/dbext.vim
    https://github.com/Raimondi/delimitMate
    https://github.com/editorconfig/editorconfig-vim
    https://github.com/powerline/fonts.git
    https://github.com/Yggdroot/indentLine
    https://github.com/othree/javascript-libraries-syntax.vim
    https://github.com/Shougo/neocomplete.vim
    https://github.com/vim-syntastic/syntastic
    https://github.com/vim-scripts/taglist.vim
    https://github.com/leafgarland/typescript-vim
    https://github.com/vim-airline/vim-airline
    https://github.com/vim-airline/vim-airline-themes
    https://github.com/alvan/vim-closetag
    https://github.com/flazz/vim-colorschemes
    https://github.com/tpope/vim-fugitive
    https://github.com/airblade/vim-gitgutter
    https://github.com/pangloss/vim-javascript
    https://github.com/heavenshell/vim-jsdoc
    https://github.com/elzr/vim-json
    https://github.com/mxw/vim-jsx
    https://github.com/posva/vim-vue
    https://github.com/lervag/vimtex
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

# add file to ~/.vim/after to allow use of locally installed eslint over global

touch ~/.vim/after/ftplugin/javascript.vim

cat > ~/.vim/after/ftplugin/javascript.vim << EOL
let s:eslint_path = system('PATH=$(npm bin --silent):$PATH && which eslint')
let b:syntastic_javascript_eslint_exec = StrTrim(s:eslint_path)
EOL

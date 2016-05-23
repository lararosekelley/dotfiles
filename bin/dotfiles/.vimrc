" vimrc
" --------

" vim, not vi
set nocompatible

" custom leader
let mapleader=","

" ======== table of contents ========
" 1. colors & fonts
" 2. ui & status line
" 3. folding, text, indents
" 4. navigation, tabs, buffers, behavior
" 5. search
" 6. helper functions
" 7. plugins
" 8. backups

" ======== 1. colors & fonts ========

" dark background color
set background=dark

" tomorrow theme
colorscheme Tomorrow-Night

" syntax highlighting
syntax on

" ======== 2. ui & statusline ========

" line numbers
set number

" show command in bottom right
set showcmd

" highlight current line
set cursorline

" only redraw when needed
set lazyredraw

" show status line
set laststatus=2

" no sounds
set visualbell

" show trailing spaces
set list listchars=trail:•

" view file tree
map <leader>; :Explore<CR>

" disable file tree history file
let g:netrw_dirhistmax=0

" ======== 3. folding, text, indents ========

" unicode
set encoding=utf-8

" allow backspace
set backspace=indent,eol,start

" spaces per tab
set tabstop=4
set softtabstop=4
set shiftwidth=4

" tabs are spaces
set expandtab

" auto indent
filetype indent plugin on
set autoindent
set smartindent

" enable folding
set foldenable

" fold based on indent
set foldmethod=indent

" show most folds
set foldlevelstart=10
set foldnestmax=10

" space toggles folds
nnoremap <space> za

" spellcheck
setlocal spell spelllang=en_us

" ======== 4. navigation, tabs, buffers, behavior ========

" enable mouse in all modes
set mouse=a

" buffers don't need to be in window
set hidden

" reload files changed outside of vim
set autoread

" store more command history
set history=1000

" source vimrc from vim
nnoremap ss :so ~/.vimrc<CR>

" markdown .md files
autocmd BufNewFile,BufRead *.md set filetype=markdown

" start scrolling 4 lines before window border
set scrolloff=4

" cycle through buffers
nnoremap <C-n> :bnext<CR>
nnoremap <C-m> :bprevious<CR>

" ======== 5. search ========

" search while typing
set incsearch

" highlight matches
set hlsearch

" ignore case when searching
set ignorecase

" ,. turns off highlights when done
nnoremap <leader>. :nohlsearch<CR>

" wildmenu
if has("wildmenu")
    " compiled files
    set wildignore+=*.a,*.o,*.pyc
    " hidden files
    set wildignore+=.DS_Store
    " images
    set wildignore+=*.bmp,*.gif,*.ico,*.jpeg,*.jpg,*.png
    " folders
    set wildignore+=.git,node_modules,.svn,.hg

    " enable it
    set wildmenu
    set wildmode=longest,list

    " use it
    inoremap <Tab> <C-X><C-F>
endif

" ======== 6. helper functions ========

" ======== 7. plugins ========

if filereadable(expand("~/.vim/autoload/pathogen.vim"))
    execute pathogen#infect()

    " CtrlP
    let g:ctrlp_map='<c-p>'
    let g:ctrlp_cmd='CtrlP'

    " Syntastic
    set statusline+=%#warningmsg#
    set statusline+=%{SyntasticStatuslineFlag()}
    set statusline+=%*

    let g:syntastic_always_populate_loc_list = 1
    let g:syntastic_auto_loc_list = 1
    let g:syntastic_check_on_open = 1
    let g:syntastic_check_on_wq = 0

    " Airline
    let g:airline#extensions#tabline#enabled = 1
endif

" ======== 8. backups ========

" turn backup on except for certain files
set backup
set writebackup
set backupskip=/tmp/*,/private/tmp/*

" centralize location of swap and backup files
set backupdir=~/.vim/backups
set directory=~/.vim/swaps

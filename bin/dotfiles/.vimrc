" vimrc
"
" vim config (pathogen for plugin management)
" --------

" -------- sections --------
"
" 1. general
" 2. ui, status line
" 3. colors, fonts
" 4. files, backups
" 5. navigation, tabs, buffers
" 6. text, indent, folding
" 7. search
" 8. helpers, plugins
"
" --------------------------

" -------- 1. general --------

" vim, not vi
set nocompatible

" -------- 2. ui, status line --------

" turn on line numbers
set number

" highlight line for text wrap
set colorcolumn=80

" show current command in bottom right of editor
set showcmd

" highlight current line
set cursorline

" only redraw when needed
set lazyredraw

" always show status line
set laststatus=2

" no sounds or flashes on error
set novisualbell
set noerrorbells
set t_vb=
set tm=500

" show trailing spaces
set list
set listchars=trail:•

" filename completion
if has("wildmenu")
    " ignore compiled files
    set wildignore+=*.a,*.o,*.pyc,*.class,*.jar
    set wildignore+=.DS_Store,.Trashes,.Spotlight-V100
    set wildignore+=*.bmp,*.gif,*.ico,*.jpeg,*.jpg,*.png
    set wildignore+=.git,node_modules,.svn,.hg

    " enable it
    set wildmenu
    set wildmode=longest,list

    " use it
    inoremap <leader><Tab> <C-X><C-F>
endif

" show ruler
set ruler

" hide abandoned buffers
set hid

" highlight matching brackets
set showmatch
set mat=2

" add extra margin to left
set foldcolumn=1

" enable mouse
set mouse=a

" -------- 3. colors, fonts --------

" syntax highlighting
syntax enable

" dark background
set background=dark

" color scheme
try
    colorscheme Tomorrow-Night
catch
    colorscheme desert
endtry

" encoding
set encoding=utf8

" -------- 4. files, backups --------

" reload files edited outside of vim
set autoread

" recognize markdown files with .md extension
autocmd BufRead,BufNewFile *.md set filetype=markdown
let g:markdown_fenced_languages = ['html', 'python', 'py=python', 'bash=sh', 'javascript', 'js=javascript', 'ruby', 'sass', 'xml', 'java']

" recognize certain rc files
autocmd BufRead,BufNewFile .{eslint,babel}rc set filetype=json

" no concealing characters
set conceallevel=0
autocmd FileType * setlocal conceallevel=0

" turn backup on
set backup
set writebackup
set backupskip=/tmp/*,/private/tmp/*

" centralize swap/backup locations
set backupdir=~/.vim/backups
set directory=~/.vim/swaps

" -------- 5. navigation, tabs, buffers --------

" force use of h,j,k,l for navigation
nnoremap <Left> :echoe "use h"<CR>
nnoremap <Right> :echoe "use l"<CR>
nnoremap <Up> :echoe "use k"<CR>
nnoremap <Down> :echoe "use j"<CR>

" custom leader
let mapleader=","

" navigate between window splits using Ctrl key
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

" use spacebar for initiating commands
nnoremap <Space> :

" managing tabs
nnoremap <S-l> gt
nnoremap <S-h> gT

" enable shift-tab to delete a tab in normal and insert mode
nnoremap <S-Tab> <<
inoremap <S-Tab> <C-d>

" cd to current file's directory
set autochdir

" return to last edit position when opening a file
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif

" keep buffers out of window
set hidden

" more history
set history=1000

" source vimrc from vim
map <leader>s :so ~/.vimrc<CR>

" scroll 4 lines before window border
set scrolloff=4

" -------- 6. text, indent, folding --------

" remove all trailing whitespace
nnoremap <leader>w :let _s=@/<Bar>:%s/\s\+$//e<Bar>:let @/=_s<Bar><CR>

" use unicode
set encoding=utf8

" allow backspace
set backspace=indent,eol,start

" use spaces for tabs
set expandtab
set smarttab

" spaces per tab
set tabstop=4
set softtabstop=4
set shiftwidth=4

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

" use f to toggle folding
nnoremap f za

" line breaks
set lbr
set tw=500

" spell checking
autocmd BufRead,BufNewFile *.md,*.txt setlocal spell spelllang=en_us
nnoremap ss :setlocal spell! spelllang=en_us<CR>
highlight clear SpellRare
highlight clear SpellCap
highlight clear SpellLocal

" -------- 7. search --------

" initiate a search with <Tab>
nnoremap <Tab> /

" search as you type
set incsearch

" highlight matches
set hlsearch

" ignore case when searching
set ignorecase

" turn off highlighting when done
nnoremap <leader>. :nohlsearch<CR>

" -------- 8. helpers, plugins --------

" plugins (via pathogen)
if filereadable(expand("~/.vim/autoload/pathogen.vim"))
    execute pathogen#infect()

    " Airline
    let g:airline#extensions#tabline#enabled=1
    let g:airline#extensions#tabline#show_tabs=1
    let g:airline#extensions#tabline#show_tab_nr=1
    let g:airline#extensions#tabline#tab_nr_type=1
    let g:airline#extensions#tabline#fnamemod=':t'
    let g:airline#extensions#tabline#show_buffers=0

    if !exists('g:airline_symbols')
        let g:airline_symbols = {}
    endif

    let g:airline_left_sep=''
    let g:airline_left_alt_sep=''
    let g:airline_right_sep=''
    let g:airline_right_alt_sep=''
    let g:airline_symbols.branch=''
    let g:airline_symbols.readonly=''
    let g:airline_symbols.linenr=''

    " NERDTree and NERDTreeTabs
    let NERDTreeShowHidden=1

    let g:nerdtree_tabs_open_on_console_startup=1
    let g:nerdtree_tabs_smart_startup_focus=2
    map <leader>/ :NERDTreeTabsToggle<CR>
    map <leader>f :NERDTreeFind<CR>

    " Javascript
    let g:javascript_plugin_jsdoc=1

    " CtrlP
    let g:ctrlp_map='<C-p>'
    let g:ctrlp_cmd='CtrlP'

    " Syntastic
    set statusline+=%#warningmsg#
    set statusline+=%{SyntasticStatuslineFlag()}
    set statusline+=%*

    let g:syntastic_always_populate_loc_list=1
    let g:syntastic_auto_loc_list=1
    let g:syntastic_check_on_open=1
    let g:syntastic_check_on_wq=0

    let g:syntastic_javascript_checkers=['eslint']

    " indentLine
    let g:indentLine_setConceal=0
endif

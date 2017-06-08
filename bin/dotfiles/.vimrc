set encoding=utf-8
scriptencoding utf-8

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

augroup vimrc
    autocmd!
augroup END

" custom map leader
let mapleader=','

" -------- 2. ui, status line --------

" turn on line numbers
set number

" highlight line for text wrap
set colorcolumn=120

" show current command in bottom right of editor
set showcmd

" highlight current line
set cursorline

" only redraw when needed
set lazyredraw

" no sounds or flashes on error
set novisualbell
set noerrorbells
set t_vb=
set tm=500

" show trailing spaces
set list
set listchars=trail:•

" filename completion
if has('wildmenu')
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

" use system clipboard
if has('clipboard')
    set clipboard=unnamed " System clipboard

    if has('unnamedplus') " X11 support
        set clipboard+=unnamedplus
    endif
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
set ttymouse=xterm2
set mouse=a

" enable filetype plugins
filetype plugin on

" omnicompletion
set omnifunc=syntaxcomplete#Complete

" -------- 3. colors, fonts --------

" syntax highlighting
syntax enable

" dark background
set background=dark

" color scheme
try
    colorscheme triplejelly

    " my custom options

    highlight Normal ctermbg=234
    highlight LineNr ctermbg=234
    highlight ColorColumn ctermbg=233
    highlight CursorLine ctermbg=233
    highlight String ctermfg=168
    highlight jsReturn ctermfg=161 cterm=bold
catch
    colorscheme Tomorrow-Night
endtry

" -------- 4. files, backups --------

" reload files edited outside of vim
set autoread

" recognize markdown files with .md extension
autocmd BufRead,BufNewFile *.md set filetype=markdown
let g:markdown_fenced_languages=[ 'html', 'python', 'py=python', 'bash=sh', 'javascript', 'js=javascript', 'ruby', 'rb=ruby', 'css', 'sql', 'sass', 'scss', 'xml', 'java' ]

" recognize certain rc files
autocmd BufRead,BufNewFile .{artillery,babel,eslint,nyc,stylelint}rc set filetype=json

" no concealing characters
set conceallevel=0
autocmd vimrc FileType * setlocal conceallevel=0

" turn backup on
set backup
set writebackup
set backupskip=/tmp/*,/private/tmp/*

" centralize swap/backup locations
set backupdir=~/.vim/backups
set directory=~/.vim/swaps

" -------- 5. navigation, tabs, buffers --------

" kill all buffers
nnoremap <leader>x :bufdo bd<CR>

" force use of h,j,k,l for navigation
nnoremap <Left> :echoe "use h"<CR>
nnoremap <Right> :echoe "use l"<CR>
nnoremap <Up> :echoe "use k"<CR>
nnoremap <Down> :echoe "use j"<CR>

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

" shift-tab for removing a tab indent
nnoremap <S-Tab> <<
inoremap <S-Tab> <C-d>

" cd to current file's directory
set autochdir

" return to last edit position when opening a file
autocmd vimrc BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif

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
autocmd vimrc BufRead,BufNewFile *.md,*.txt setlocal spell spelllang=en_us
nnoremap ss :setlocal spell! spelllang=en_us<CR>
highlight clear SpellRare
highlight clear SpellCap
highlight clear SpellLocal

" -------- 7. search --------

" initiate a search with <Tab> in normal mode
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

" helper functions
function! StrTrim(text)
    return substitute(a:text, '^\n*\s*\(.\{-}\)\n*\s*$', '\1', '')
endfunction

" plugins (via pathogen)
if filereadable(expand('~/.vim/autoload/pathogen.vim'))
    " load pathogen
    execute pathogen#infect()

    " airline
    let g:airline#extensions#tabline#enabled=1
    let g:airline#extensions#tabline#show_tabs=1
    let g:airline#extensions#tabline#show_tab_nr=1
    let g:airline#extensions#tabline#tab_nr_type=1
    let g:airline#extensions#tabline#fnamemod=':t'
    let g:airline#extensions#tabline#show_buffers=0

    if !exists('g:airline_symbols')
        let g:airline_symbols={}
    endif

    let g:airline_left_sep=''
    let g:airline_left_alt_sep=''
    let g:airline_right_sep=''
    let g:airline_right_alt_sep=''
    let g:airline_symbols.branch=''
    let g:airline_symbols.readonly=''
    let g:airline_symbols.linenr=''

    " airline theme
    let g:airline_theme='jellybeans'

    " close tags
    let g:closetag_filenames='*.html,*.xhtml,*.phtml,*.xml'

    " csv
    let g:csv_delim=','
    let g:csv_nomap_cr=1
    let g:csv_nomap_space=1
    let g:csv_nomap_bs=1

    " ctrl-p
    let g:ctrlp_map='<c-p>'
    let g:ctrlp_cmd='CtrlP'

    " editorconfig
    let g:EditorConfig_exclude_patterns=[ 'fugitive://.*' ]

    " indentLine
    let g:indentLine_color_term=237
    let g:indentLine_setConceal=0

    " javascript libraries
    let g:used_javascript_libs='d3,jquery,vue,react,flux,backbone'

    " javascript
    let g:javascript_plugin_jsdoc=1
    let g:javascript_plugin_flow=1

    " flow - close when there are no errors
    let g:flow#autoclose=1

    " json
    let g:vim_json_syntax_conceal=0

    " latex
    let g:tex_flavor='latex'

    " markdown
    let g:markdown_syntax_conceal=0

    " ycm settings
    let g:ycm_key_list_select_completion=[ '<C-n>', '<Down>' ]
    let g:ycm_key_list_previous_completion=[ '<C-p>', '<Up>' ]
    let g:SuperTabDefaultCompletionType='<C-n>'

    " snippets - cycle through suggestions
    let g:UltiSnipsExpandTrigger='<Tab>'
    let g:UltiSnipsJumpForwardTrigger='<Tab>'
    let g:UltiSnipsJumpBackwardTrigger='<S-Tab>'

    " syntastic
    let g:syntastic_always_populate_loc_list=1
    let g:syntastic_auto_loc_list=1
    let g:syntastic_check_on_open=1
    let g:syntastic_check_on_wq=0

    " syntastic language checkers (only works if each checker binary is installed)
    let g:syntastic_javascript_checkers=[ 'eslint' ]
    let g:syntastic_ruby_checkers=[ 'rubocop' ]
    let g:syntastic_json_checkers=[ 'jsonlint' ]
    let g:syntastic_python_checkers=[ 'flake8' ]
    let g:syntastic_markdown_checkers=[ 'mdl' ]
    let g:syntastic_html_checkers=[ 'tidy' ]
    let g:syntastic_html_tidy_exec='tidy5'
    let g:syntastic_css_checkers=[ 'csslint' ]
    let g:syntastic_scss_checkers=[ 'stylelint' ]
    let g:syntastic_java_checkers=[ 'javac' ]
    let g:syntastic_sql_checkers=[ 'sqlint' ]
    let g:syntastic_tex_checkers=[ 'chktex' ]
    let g:syntastic_bash_checkers=[ 'shellcheck' ]
    let g:syntastic_sh_checkers=[ 'shellcheck' ]
    let g:syntastic_typescript_checkers=[ 'tslint' ]
    let g:syntastic_vim_checkers=[ 'vint' ]

    " set the statusline
    set statusline+=%{fugitive#statusline()}
    set statusline+=%#warningmsg#
    set statusline+=%{SyntasticStatuslineFlag()}
    set statusline+=%*

    if has('statusline')
        set laststatus=2
        set statusline=%<%f\
        set statusline+=%w%h%m%r
        set statusline+=%{fugitive#statusline()}
        set statusline+=\ [%{&ff}/%Y]
        set statusline+=\ [%{getcwd()}]
        set statusline+=%#warningmsg#
        set statusline+=%{SyntasticStatuslineFlag()}
        set statusline+=%*
        let g:syntastic_enable_signs=1
        set statusline+=%=%-14.(%l,%c%V%)\ %p%%
    endif
endif

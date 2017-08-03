set encoding=utf-8
scriptencoding utf-8

" vimrc
"
" vim config w/ vim-plug for plugin management
" --------------------------------------------

" -------- sections --------
"
" 1. general
" 2. ui, colors, fonts
" 3. files
" 4. navigation, tabs, buffers
" 5. text, indent, folding
" 6. search
" 7. helper functions
" 8. plugins
"
" --------------------------

" ----------
" 1. general
" ----------

augroup vimrc
    autocmd!
augroup END

" change leader key
let mapleader=','

" --------------------
" 2. ui, colors, fonts
" --------------------

" syntax highlighting
syntax enable

" darker background
set background=dark

" line numbering
set number

" highlight line length limit
set colorcolumn=120

" show current command in bottom right of editor
set showcmd

" highlight current line
set cursorline

" only redraw when needed
set lazyredraw

" no sounds and flashing on error
set novisualbell
set noerrorbells
set t_vb=
set tm=500

" show trailing spaces
set list
set listchars=trail:•

" show ruler
set ruler

" hide abandoned buffers
set hid

" highlight matching brackets
set showmatch
set mat=2

" larger margin on the left
set foldcolumn=1

" filename completion
if has('wildmenu')
    " ignore compiled files
    set wildignore+=*.a,*.o
    set wildignore+=*.pyc,*.egg
    set wildignore+=*.class,*.jar
    set wildignore+=.DS_Store,.Trashes,.Spotlight-V100
    set wildignore+=*.bmp,*.gif,*.ico,*.jpeg,*.jpg,*.png
    set wildignore+=.git,.svn,.hg

    " enable wildmenu
    set wildmenu
    set wildmode=longest:list,full
endif

" --------
" 3. files
" --------

" reload files edited outside of vim
set autoread

augroup autoread
    autocmd!
    autocmd FocusGained,BufEnter * :silent! !
    autocmd FocusLost,WinLeave * :silent! noautocmd w
augroup END

" recognize certain .rc files as json
autocmd BufRead,BufNewFile,BufFilePre .{artillery,babel,eslint,nyc,stylelint}rc set filetype=json

" no concealing characters
set conceallevel=0

" no swaps or backups
set nobackup
set nowritebackup
set noswapfile

" persistent undo
set undofile

" ----------------------------
" 4. navigation, tabs, buffers
" ----------------------------

" send more chars at once
set ttyfast

" enable mouse mode
set ttymouse=xterm2
set mouse=a

" make backspace work like any other editor
set backspace=indent,eol,start

" wrap to prev / next lines with arrow keys
set whichwrap+=<,>,h,l,[,]

" kill all active buffers
nnoremap <leader>x :bufdo bd<CR>

" force use of h,j,k,l for navigation with error message
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
augroup last_position
    autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
augroup END

" keep buffers out of window
set hidden

" more history
set history=1000

" pad scrolling 4 lines from window border
set scrolloff=4

" always show status and tab bars
set laststatus=2
set showtabline=2

" ------------------------
" 5. text, indent, folding
" ------------------------

" enable filetype plugins
filetype plugin on

" omnicomplete
set omnifunc=syntaxcomplete#Complete

" use system clipboard
if has('clipboard')
    set clipboard=unnamed
endif

" remove all trailing whitespace
nnoremap <leader>w :let _s=@/<Bar>:%s/\s\+$//e<Bar>:let @/=_s<Bar><CR>

" use spaces for tabs
set expandtab
set smarttab
set tabstop=4
set softtabstop=4
set shiftwidth=4

" auto indent
filetype indent plugin on
set autoindent
set smartindent

" text folding
set foldenable
set foldmethod=indent
set foldlevelstart=10
set foldnestmax=10

" use f to fold in normal mode
nnoremap f za

" line breaks
set lbr
set tw=500

" spell check
autocmd vimrc BufRead,BufNewFile *.md,*.txt setlocal spell spelllang=en_us
nnoremap ss :setlocal spell! spelllang=en_us<CR>
highlight clear SpellRare
highlight clear SpellCap
highlight clear SpellLocal

" ---------
" 6. search
" ---------

" use <Tab> in normal mode to start search
nnoremap <Tab> /

" realtime search
set incsearch

" highlight matches
set hlsearch

" ignore case when searching
set ignorecase

" turn off search highlight
nnoremap <leader>. :noh<CR>

" -------------------
" 7. helper functions
" -------------------

" helper functions
function! StrTrim(text)
    return substitute(a:text, '^\n*\s*\(.\{-}\)\n*\s*$', '\1', '')
endfunction

" ----------
" 8. plugins
" ----------

call plug#begin('~/.vim/packages')

" color scheme
Plug 'morhetz/gruvbox'

" automatically close brackets, quotes, etc.
Plug 'jiangmiao/auto-pairs'

" close html tags
Plug 'alvan/vim-closetag'

let g:closetag_filenames='*.html,*.xhtml,*.phtml,*.xml,*.vue'

" highlight colors
Plug 'ap/vim-css-color'

" csv files
Plug 'chrisbra/csv.vim'

let g:csv_delim=','
let g:csv_nomap_cr=1
let g:csv_nomap_space=1
let g:csv_nomap_bs=1

" look up documentation
Plug 'keith/investigate.vim'

let g:investigate_use_dash=1

" editorconfig
Plug 'editorconfig/editorconfig-vim'

let g:EditorConfig_exclude_patterns=[ 'fugitive://.*', 'scp://.*' ]

" git
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'

" database access
Plug 'vim-scripts/dbext.vim'

" show indentation levels next to line numbers
Plug 'Yggdroot/indentLine'

" javascript config
Plug 'pangloss/vim-javascript'

let g:javascript_plugin_jsdoc=1

Plug 'othree/javascript-libraries-syntax.vim'

let g:used_javascript_libs='jquery,underscore,backbone,react,flux,handlebars,vue,d3'

" better json highlighting
Plug 'elzr/vim-json'

let g:vim_json_syntax_conceal=0

" latex
Plug 'lervag/vimtex'

let g:tex_flavor='latex'

" better markdown
Plug 'plasticboy/vim-markdown'

let g:vim_markdown_fenced_languages=[ 'csharp=cs', 'js=javascript', 'rb=ruby', 'c++=cpp' ]
let g:vim_markdown_conceal=0

" supertab
Plug 'ervandew/supertab'

let g:SuperTabDefaultCompletionType='<C-n>'
let g:SuperTabCrMapping=0

" code completion via ycm
Plug 'Valloric/YouCompleteMe', { 'do': '/usr/bin/python ./install.py' }

let g:ycm_key_list_select_completion=[ '<C-j>', '<C-n>', '<Down>' ]
let g:ycm_key_list_previous_completion=[ '<C-k>', '<C-p>', '<Up>' ]

" snippets
Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'

let g:UltiSnipsExpandTrigger='<Tab>'
let g:UltiSnipsJumpForwardTrigger='<Tab>'
let g:UltiSnipsJumpBackwardTrigger='<S-Tab>'
let g:UltiSnipsSnippetDirectories=[ 'UltiSnips', 'snips' ]

" syntax errors and warnings
Plug 'vim-syntastic/syntastic'
Plug 'posva/vim-vue'
Plug 'sekel/vim-vue-syntastic'

let g:syntastic_always_populate_loc_list=1
let g:syntastic_auto_loc_list=1
let g:syntastic_check_on_open=1
let g:syntastic_check_on_wq=0
let g:syntastic_enable_highlighting=1

" syntastic checkers

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
let g:syntastic_vue_checkers=[ 'eslint' ]

" make syntastic work for js and vue files with locally installed eslint

let local_eslint = finddir('node_modules', '.;') . '/.bin/eslint'

if matchstr(local_eslint, "^\/\\w") == ''
    let local_eslint = getcwd() . "/" . local_eslint
endif

if executable(local_eslint)
    let g:syntastic_javascript_eslint_exec = local_eslint
    let g:syntastic_vue_eslint_exec = local_eslint
endif

" configure status and tab lines
Plug 'itchyny/lightline.vim'

let g:lightline = {
        \ 'colorscheme': 'gruvbox',
        \ 'enable': { 'tabline': 1 },
        \ 'active': {
        \     'left': [
        \         [ 'mode', 'paste', 'spell' ],
        \         [ 'gitbranch', 'readonly', 'filename', 'modified' ]
        \     ],
        \     'right': [
        \         [ 'syntastic', 'lineinfo' ],
        \         [ 'percent' ],
        \         [ 'fileformat', 'fileencoding', 'filetype' ]
        \     ]
        \ },
        \ 'component_function': {
        \     'gitbranch': 'fugitive#head'
        \ },
        \ 'component_expand': {
        \     'syntastic': 'SyntasticStatuslineFlag'
        \ },
        \ 'component_type': {
        \     'syntastic': 'error'
        \ }
    \ }

augroup AutoSyntastic
    autocmd!
    autocmd BufWritePost * call s:syntastic()
augroup END

function! s:syntastic()
    SyntasticCheck
    call lightline#update()
endfunction

" custom start screen
Plug 'mhinz/vim-startify'

call plug#end()

" set colorscheme
try
    colorscheme gruvbox
catch
    colorscheme ron
endtry

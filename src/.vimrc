set encoding=utf-8
set fileencoding=utf-8

" --------
" File: .vimrc
" Description: Vim configuration
" Author: Ty-Lucas Kelley <tylucaskelley@gmail.com>
" Source: https://github.com/tylucaskelley/setup
" Last Modified: 11 December 2018
" --------

" -------- sections --------
"
" 1. general
" 2. key mappings
" 3. ui, colors, fonts
" 4. files
" 5. navigation, tabs, buffers
" 6. text, indent, folding
" 7. search
" 8. helper functions
" 9. plugins
"
" --------

" ----------
" 1. general
" ----------

" use , as leader key
let g:mapleader=','

" longer command history
set history=5000

" get rid of escape key delay
set timeoutlen=1000
set ttimeoutlen=10

" allow for filetype-specific plugins
filetype plugin indent on

" ---------------
" 2. key mappings
" ---------------

" kill search result highlighting
nnoremap <silent> <CR> :noh<CR><CR>

" select entire file's contents
nnoremap <leader>a ggVG

" delete everything in a file
nnoremap <leader>d ggdG

" copy entire file's contents to system clipboard and return to previous cursor position
nnoremap <leader>c gg"+yG``

" force use of hjkl for navigation in normal mode
nnoremap <Left> :echoe "use h to move left"<CR>
nnoremap <Right> :echoe "use l to move right"<CR>
nnoremap <Up> :echoe "use k to move up"<CR>
nnoremap <Down> :echoe "use j to move down"<CR>

" navigate between window splits with Ctrl keys
nnoremap <C-l> <C-w>l
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k

" initiate commands with spacebar
nnoremap <Space> :

" initiate search with <Tab> in normal mode
nnoremap <Tab> /

" move between tabs with Shift-l and Shift-h
nnoremap <S-l> gt
nnoremap <S-h> gT

" close all open buffers
nnoremap <leader>x :bufdo bd<CR>

" split windows
nnoremap <leader>h :split<CR>
nnoremap <leader>v :vsplit<CR>

" resize window splits to be equal
nnoremap <leader>e <C-w>=

" reload .vimrc
nnoremap <leader>. :source ~/.vimrc<CR>

" remove all trailing whitespace in file
nnoremap <leader>w :let _s=@/<Bar>:%s/\s\+$//e<Bar>:let @/=_s<Bar><CR>

" change 4 space indentation to 2
nnoremap <leader>2 :%s;^\(\s\+\);\=repeat(' ', len(submatch(0))/2);g<CR>:set ts=2 sts=2 noet<CR><CR>

" change 2 space indentation to 4
nnoremap <leader>4 :%s/^\s*/&&<CR>:set ts=4 sts=4 et<CR><CR>

" re-indent entire file
nnoremap <leader>i mzgg=G`z`

" toggle fold open/close
nnoremap <leader>, za

" start substitution
nnoremap <leader>s :%s/\<<C-r><C-w>\>/

" select entire file contents
nnoremap <leader>a ggVG

" copy entire file contents to system clipboard and return to previous cursor position
nnoremap <leader>c gg"+yG``

" turn paste mode off
nnoremap <leader>p :set nopaste<CR>

" adjust indentation
inoremap <S-Tab> <C-D>
vnoremap <Tab> >gv
vnoremap <S-Tab> <gv

" backspace to delete in visual mode
vnoremap <BS> d

" helpful git stuff
augroup GitRebase
  autocmd!
  autocmd FileType gitrebase nnoremap <buffer> <leader>s :2,$s/^pick/squash/<CR>
augroup END

" exit terminal-mode
tnoremap <Esc> <C-\><C-n>

" --------------------
" 3. ui, colors, fonts
" --------------------

" support truecolor
if has('termguicolors')
  set termguicolors
endif

" turn on syntax highlighting
syntax enable

" dark background
set background=dark

" show line at column 120
set colorcolumn=120

" show current command in bottom right
set showcmd

" highlight current line
set cursorline

" only redraw when needed
set lazyredraw

" terminal bell settings
set noerrorbells
set visualbell
set t_vb=

" display special characters
set list
set listchars=tab:>\ ,trail:-,extends:>,precedes:<,nbsp:+

" line and column numbers
set ruler
set number

" don't warn about unsaved changes to buffers
set hidden

" highlight matching braces
set showmatch
set matchtime=2

" show result of various commands like search/replace before you commit
if has('nvim')
  set inccommand=split
endif

" --------
" 4. files
" --------

" filename completion
if has('wildmenu')
  " ignore case
  set wildignorecase

  " ignore some filetypes
  set wildignore+=*.a,*.o
  set wildignore+=*.pyc,*.egg
  set wildignore+=*.class,*.jar
  set wildignore+=.DS_Store,.Trashes,.Spotlight-V100
  set wildignore+=*.bmp,*.gif,*.ico,*.jpeg,*.jpg,*.png
  set wildignore+=.git,.svn,.hg

  " enable it
  set wildmenu
  set wildmode=longest:full,full
endif

" recognize some specific files
augroup RecognizeFiles
  autocmd!
  autocmd BufRead,BufNewFile,BufFilePre .{artilleryrc,babelrc,eslintrc,jsdocrc,nycrc,stylelintrc,markdownlintrc,tern-project,tern-config} set filetype=json
  autocmd BufRead,BufNewFile,BufFilePre Procfile,.prettierrc set filetype=yaml
  autocmd BufRead,BufNewFile,BufFilePre .{flake8,licenser,flowconfig} set filetype=dosini
  autocmd BufRead,BufNewFile,BufFilePre .{sequelizerc,jestconfig,fxrc} set filetype=javascript
  autocmd BufRead,BufNewFile,BufFilePre *.jsx set filetype=javascript.jsx
  autocmd BufRead,BufNewFile,BufFilePre *.tsx set filetype=typescript.tsx
augroup END

" no concealing characters
set conceallevel=0

" no swaps and backups
set nobackup
set nowritebackup
set noswapfile

" persistent undo
set undofile
set undodir=~/.vim/undo

" ----------------------------
" 5. navigation, tabs, buffers
" ----------------------------

" make backspace work like other editors
set backspace=indent,eol,start

" send more chars at once
set ttyfast

" enable mouse mode
if !has('nvim')
  set ttymouse=xterm2
endif

set mouse=a

" wrap to prev/next line with arrow keys
set whichwrap=<,>,h,l,[,]

" open splits below and to the right
set splitright
set splitbelow

" don't cd to current file's directory automatically
set noautochdir

" return to last edit position when opening a file
augroup last_position
  autocmd!
  autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
augroup END

" pad scrolling with a few lines from window border
set scrolloff=10
set sidescrolloff=10

" always show status and tab bars
set laststatus=2
set showtabline=2

" close location list if parent window is quit
augroup LocList
  autocmd!
  autocmd QuitPre * silent! lclose
augroup END

" ------------------------
" 6. text, indent, folding
" ------------------------

" sync with system clipboard
if has('clipboard')
  set clipboard=unnamedplus
endif

" spaces instead of tabs, width of 2
set tabstop=2
set softtabstop=0
set expandtab
set shiftwidth=2
set smarttab

" auto indent
set autoindent
set smartindent

" proper word wrapping
set wrap
set textwidth=0
set wrapmargin=0
set linebreak

" grep-style regex
set magic

" max number of folds to create
set foldnestmax=10

" language-based folding
set foldmethod=indent

" display fold info
set foldcolumn=4

" folds open by default when reading file
set nofoldenable
set foldlevelstart=99

" spellcheck for markdown and text files automatically
augroup Spelling
  autocmd!
  autocmd BufRead,BufNewFile *.md,*.txt setlocal spell spelllang=en_us
augroup END

" ---------
" 7. search
" ---------

" add the g flag to search and replace
set gdefault

" real-time search
set incsearch

" highlight matches
set hlsearch

" ignore case when searching
set ignorecase

" -------------------
" 8. helper functions
" -------------------

nmap <leader>hg :call <SID>HighlightGroups()<CR>

" show highlight groups applied to current text
function! <SID>HighlightGroups()
  if !exists('*synstack')
    return
  endif

  echo map(synstack(line('.'), col('.')), "synIDattr(v:val, 'name')")
endfunction

" trim whitespace from a string
function! StrTrim(text)
  return substitute(a:text, '^\n*\s*\(.\{-}\)\n*\s*$', '\1', '')
endfunction

" ----------
" 9. plugins
" ----------

if !empty(glob('~/.vim/autoload/plug.vim'))
  call plug#begin('~/.vim/packages')

  " ----------
  " ui changes
  " ----------

  " color schemes
  Plug 'morhetz/gruvbox'

  " lightline
  Plug 'itchyny/lightline.vim'
  Plug 'maximbaz/lightline-ale'

  let g:lightline={
    \ 'enable': { 'tabline': 1 },
    \ 'active': {
    \   'left': [
    \     [ 'mode', 'paste', 'spell' ],
    \     [ 'gitbranch', 'readonly', 'relativepath', 'modified' ]
    \   ],
    \   'right': [
    \     [ 'ale_errors', 'ale_warnings', 'ale_ok', 'lineinfo' ],
    \     [ 'fileformat', 'fileencoding', 'filetype', 'bufnum' ]
    \   ]
    \ },
    \ 'component_expand': {
    \   'ale_errors': 'lightline#ale#errors',
    \   'ale_warnings': 'lightline#ale#warnings',
    \   'ale_ok': 'lightline#ale#ok'
    \ },
    \ 'component_type': {
    \   'ale_errors': 'error',
    \   'ale_warnings': 'warning',
    \   'ale_ok': 'left'
    \ },
    \ 'component_function': {
    \   'gitbranch': 'fugitive#head'
    \ },
  \ }

  " nicer start screen
  Plug 'mhinz/vim-startify'

  let g:startify_bookmarks=[ '~/.vimrc', '~/.bashrc', '~/.aliases', '~/.functions', '~/.exports', '~/.env' ]

  " merge two tabs
  Plug 'vim-scripts/Tabmerge'

  nnoremap <leader>tm :execute "Tabmerge left"<CR>

  " show indent guides
  Plug 'Yggdroot/indentLine'

  let g:indentLine_setColors=0
  let g:indentLine_setConceal=0

  " show yanked region
  Plug 'machakann/vim-highlightedyank'

  " ---
  " git
  " ---

  " git wrapper
  Plug 'tpope/vim-fugitive'
  Plug 'tpope/vim-rhubarb'

  nnoremap <leader>yg :.Gbrowse!<CR>

  " show diff in gutter
  Plug 'airblade/vim-gitgutter'

  " -----
  " files
  " -----

  " unix commands like :Rename and :SudoEdit
  Plug 'tpope/vim-eunuch'

  " bookmark lines and comment
  Plug 'MattesGroeger/vim-bookmarks'

  " add in keywords to close code blocks (e.g. endif, end, done, etc.)
  Plug 'tpope/vim-endwise'

  " reload files changed outside of vim
  Plug 'djoshea/vim-autoread'

  " quick commenting of lines (<leader>cc being most useful)
  Plug 'scrooloose/nerdcommenter'

  let g:NERDSpaceDelims=1
  let g:NERDDefaultAlign='left'
  let g:NERDCommentEmptyLines=1
  let g:NERDTrimTrailingWhitespace=1

  " fuzzy file finding
  Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --bin' }
  Plug 'junegunn/fzf.vim'

  let g:fzf_command_prefix='Fzf'

  let g:fzf_colors={
    \ 'fg':      [ 'fg', 'Normal' ],
    \ 'bg':      [ 'bg', 'Normal' ],
    \ 'hl':      [ 'fg', 'Comment' ],
    \ 'fg+':     [ 'fg', 'CursorLine', 'CursorColumn', 'Normal' ],
    \ 'bg+':     [ 'bg', 'CursorLine', 'CursorColumn' ],
    \ 'hl+':     [ 'fg', 'Statement' ],
    \ 'info':    [ 'fg', 'PreProc' ],
    \ 'border':  [ 'fg', 'Ignore' ],
    \ 'prompt':  [ 'fg', 'Conditional' ],
    \ 'pointer': [ 'fg', 'Exception' ],
    \ 'marker':  [ 'fg', 'Keyword' ],
    \ 'spinner': [ 'fg', 'Label' ],
    \ 'header':  [ 'fg', 'Comment' ]
  \ }

  let g:fzf_history_dir='~/.local/share/fzf-history'

  " fuzzy file finding
  nnoremap <silent> <leader>f :FzfGFiles<CR>
  nnoremap <silent> <leader>F :FzfFiles<CR>
  nnoremap <silent> <leader>r :FzfRg<CR>

  command! -bang -nargs=? -complete=dir FzfFiles
    \ call fzf#vim#files(<q-args>, fzf#vim#with_preview(), <bang>0)

  command! -bang -nargs=? -complete=dir FzfGFiles
    \ call fzf#vim#gitfiles(<q-args>, fzf#vim#with_preview(), <bang>0)

  command! -bang -nargs=* FzfRg
    \ call fzf#vim#grep(
      \ 'rg --column --line-number --no-heading --color=always --smart-case '.shellescape(<q-args>),
      \ 1,
      \ fzf#vim#with_preview('right:50%'),
      \ <bang>0
    \ )

  augroup TermEsc
    if has('nvim')
      autocmd TermOpen * tnoremap <Esc> <c-\><c-n>
      autocmd FileType fzf tunmap <Esc>
    endif
  augroup END


  " match pairs
  Plug 'jiangmiao/auto-pairs'

  let g:AutoPairsFlyMode=0

  " recognize indent settings per project
  Plug 'tpope/vim-sleuth'

  " ---------------
  " syntax checking
  " ---------------

  Plug 'w0rp/ale'

  let g:ale_completion_enabled=1
  let g:ale_open_list=1
  let g:ale_echo_msg_format='[%linter%] %s'
  let g:ale_linters_explicit=1

  let g:ale_linter_aliases={
    \ 'vue': [ 'css', 'typescript' ],
    \ 'jsx': [ 'css', 'javascript' ],
    \ 'tsx': [ 'css', 'typescript' ]
  \ }

  let g:ale_linters={
    \ 'css': [ 'stylelint' ],
    \ 'javascript': [ 'stylelint', 'eslint' ],
    \ 'jsx': [ 'stylelint', 'eslint' ],
    \ 'typescript': [ 'stylelint', 'eslint' ],
    \ 'tsx': [ 'stylelint', 'eslint' ],
    \ 'vue': [ 'stylelint', 'eslint' ],
    \ 'markdown': [ 'markdownlint' ],
    \ 'python': [ 'pycodestyle' ],
    \ 'ruby': [ 'rubocop' ],
    \ 'sass': [ 'stylelint' ],
    \ 'scss': [ 'stylelint' ],
    \ 'sh': [ 'shellcheck' ],
    \ 'vim': [ 'vint' ]
  \ }

  let g:ale_ruby_rubocop_executable='bundle'

  " --------------
  " autocompletion / language servers
  " --------------

  if has('nvim')
    Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
  else
    Plug 'Shougo/deoplete.nvim'
    Plug 'roxma/nvim-yarp'
    Plug 'roxma/vim-hug-neovim-rpc'
  endif

  let g:node_host_prog=expand('/usr/local/bin/neovim-node-host')

  let g:python_host_prog=expand('~/.pyenv/versions/neovim2/bin/python')
  let g:python3_host_prog=expand('~/.pyenv/versions/neovim3/bin/python')

  let g:deoplete#enable_at_startup=1

  Plug 'autozimu/LanguageClient-neovim', { 'branch': 'next', 'do': 'bash install.sh' }

  let g:LanguageClient_serverCommands={
    \ 'javascript': [ 'javascript-typescript-stdio' ],
    \ 'javascript.jsx': [ 'javascript-typescript-stdio' ],
    \ 'json': [ 'vscode-json-languageserver' ],
    \ 'python': [ '~/.pyenv/shims/pyls' ],
    \ 'ruby': [ '~/.rbenv/shims/solargraph' ],
    \ 'sh': [ 'bash-language-server', 'start' ],
    \ 'typescript': [ 'javascript-typescript-stdio' ],
    \ 'typescript.tsx': [ 'javascript-typescript-stdio' ],
    \ 'vue': [ 'vls' ]
  \ }

  nnoremap <silent> K :call LanguageClient#textDocument_hover()<CR>
  nnoremap <silent> gd :call LanguageClient#textDocument_definition()<CR>
  nnoremap <silent> <F2> :call LanguageClient#textDocument_rename()<CR>

  " -------------------------
  " filetype-specific plugins
  " -------------------------

  " html / css
  Plug 'JulesWang/css.vim'
  Plug 'mattn/emmet-vim'

  let g:user_emmet_settings={
    \ 'javascript.jsx': {
    \   'extends': 'jsx',
    \ }
  \ }

  Plug 'alvan/vim-closetag'

  let g:closetag_filenames='*.html,*.xhtml,*.phtml,*.xml,*.vue,*.jsx,*.js,*.erb,*.tsx'

  " javascript / typescript / coffeescript
  Plug 'pangloss/vim-javascript'

  let g:javascript_plugin_jsdoc=1
  let g:javascript_plugin_flow=1

  " Plug 'HerringtonDarkholme/yats.vim'
  Plug 'leafgarland/typescript-vim'
  Plug 'styled-components/vim-styled-components', { 'branch': 'main' }
  Plug 'yardnsm/vim-import-cost', { 'do': 'npm install' }
  Plug 'prettier/vim-prettier', { 'do': 'npm install' }

  Plug 'kchmck/vim-coffee-script'

  " jsx / tsx
  Plug 'maxmellon/vim-jsx-pretty'

  let g:vim_jsx_pretty_colorful_config=1

  " mdx
  Plug 'jxnblk/vim-mdx-js'

  " vue
  Plug 'posva/vim-vue'

  augroup VimHighlight
    autocmd FileType vue syntax sync fromstart
  augroup END

  " graphql
  Plug 'jparise/vim-graphql'

  " json
  Plug 'elzr/vim-json'

  let g:vim_json_syntax_conceal=0

  " toml
  Plug 'cespare/vim-toml'

  " php / blade
  Plug 'jwalton512/vim-blade'

  " markdown
  Plug 'plasticboy/vim-markdown'

  let g:vim_markdown_conceal=0
  let g:vim_markdown_fenced_languages=[ 'cs=csharp', 'js=javascript', 'rb=ruby', 'c++=cpp', 'ini=dosini', 'bash=sh', 'viml=vim' ]

  " ruby
  Plug 'vim-ruby/vim-ruby'
  Plug 'tpope/vim-rails'
  Plug 'tpope/vim-bundler'
  Plug 'asux/vim-capybara'

  " graphviz
  Plug 'wannesm/wmgraphviz.vim'

  " csv
  Plug 'chrisbra/csv.vim'

  let g:csv_delim=','
  let g:csv_nomap_cr=1
  let g:csv_nomap_space=1
  let g:csv_nomap_bs=1

  " latex
  Plug 'lervag/vimtex'

  let g:tex_flavor='latex'
  let g:vimtex_compiler_progname=expand('~/.pyenv/versions/neovim3/bin/nvr')

  " vim
  Plug 'junegunn/vader.vim'

  " jenkins
  Plug 'martinda/Jenkinsfile-vim-syntax'

  " -------
  " testing
  " -------

  " kick off tests
  Plug 'janko-m/vim-test'
  Plug 'tpope/vim-dispatch'

  nnoremap <leader>t :TestFile<CR>
  nnoremap <leader>T :TestNearest<CR>

  let test#strategy='dispatch'
  let test#ruby#minitest#file_pattern='\.test\.rb'

  " -----
  " misc.
  " -----

  " smooth scrolling with <C-d> and <C-u>
  Plug 'yuttie/comfortable-motion.vim'

  " navigate between vim and tmux seamlessly
  Plug 'christoomey/vim-tmux-navigator'

  " emoji support
  Plug 'junegunn/vim-emoji'

  set completefunc=emoji#complete

  " standardize vim async api
  Plug 'prabirshrestha/async.vim'

  " make vim project-aware
  Plug 'airblade/vim-rooter'

  let g:rooter_resolve_links=1

  " look up documentation
  Plug 'keith/investigate.vim'

  " better find and replace
  Plug 'tpope/vim-abolish'

  let g:investigate_use_dash=1

  call plug#end()
end

" set colorscheme after plugin stuff is done
try
  colorscheme gruvbox
  let g:lightline.colorscheme='gruvbox'
catch
  colorscheme ron
endtry

" NOTE: This configuration has been superseded by NeoVim setup in ~/.config/nvim/init.lua
"
" ---------------------------------
" table of contents
"
" 1. general
"     a. neovim
" 2. key mappings
"     a. leader commands
" 3. navigation and search
" 4. text, indentation, and folding
" 5. appearance
" 6. files and backups
" 7. helper functions
" 8. plugins
"    a. appearance
"    b. navigation and search
"    c. git
"    d. files and projects
"    e. testing
"    f. languages
"    g. autocompletion and linting
"    h. misc.
" ---------------------------------

" ----------
" 1. general
" ----------

" use utf-8 for display and file output
set encoding=utf-8
set fileencoding=utf-8

" longer command history
set history=10000

" ----------
" 1a. neovim
" ----------

" disable perl
let g:loaded_perl_provider=0

" check for executables
let python2_executable=expand('~/.pyenv/versions/neovim2.7/bin/python')
let python3_executable=expand('~/.pyenv/versions/neovim3.9/bin/python')

if filereadable(python2_executable) && filereadable(python3_executable)
  " neovim plugins
  let g:python_host_prog=expand(python2_executable)
  let g:python3_host_prog=expand(python3_executable)
else
  echoerr 'Missing Python executables!'
endif

" ---------------
" 2. key mappings
" ---------------

" initiate commands with space
nnoremap <Space> :

" use left and right arrow keys for jumping
nnoremap <Left> <C-o>
nnoremap <Right> <C-i>

" navigate between window splits with Ctrl keys
nnoremap <C-l> <C-w>l
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k

" initiate search with tab key
nnoremap <Tab> /

" switch tabs with Shift-l and Shift-h
nnoremap <S-k> gt
nnoremap <S-j> gT

" hitting enter also removes search highlighting
nnoremap <silent> <CR> :noh<CR><CR>

" decrease indent in insert mode
inoremap <S-Tab> <C-D>

" decrease indent in visual mode
vnoremap <S-Tab> <gv

" increase indent in visual mode
vnoremap <Tab> >gv

" exit terminal mode
tnoremap <Esc> <C-\><C-n>

" -------------------
" 2a. leader commands
" -------------------

" use comma as leader key
let g:mapleader=','

" kill all open buffers
nnoremap <leader>x :bufdo bd<CR>

" close tabs to the right
nnoremap <leader>X :.+1,$tabdo :q<CR>

" select all content in file
nnoremap <leader>a ggVG

" reformat all content in file
nnoremap <leader>z ggVGgq

" copy file content to clipboard
nnoremap <leader>c gg"*yG``

" create blank vertical split
nnoremap <leader>v :vnew<CR>

" create blank horizontal split
nnoremap <leader>h <C-w>n

" make window splits equal size
nnoremap <leader>e <C-w>=

" remove all trailing whitespace in file
nnoremap <leader>w :let _s=@/<Bar>:%s/\s\+$//e<Bar>:let @/=_s<Bar><CR>

" change 4 space indentation to 2
nnoremap <leader>2 :%s;^\(\s\+\);\=repeat(' ', len(submatch(0))/2);g<CR>:set ts=2 sts=2 noet<CR><CR>

" change 2 space indentation to 4
nnoremap <leader>4 :%s/^\s*/&&<CR>:set ts=4 sts=4 et<CR><CR>

" re-indent entire file
nnoremap <leader>i mzgg=G`z`

" reformat file
nnoremap <leader>g ggVGgq

" toggle fold open/close
nnoremap <leader>. za

" start find/replace
nnoremap <leader>s :%s/\<<C-r><C-w>\>/

" turn paste mode off
nnoremap <leader>p :set nopaste<CR>

" squash everything beneath top commit while rebasing
augroup GitRebase
  autocmd!
  autocmd FileType gitrebase nnoremap <buffer> <leader>s :2,$s/^pick/squash/<CR>
augroup end

" show highlight groups (definition below)
nnoremap <leader>hg :call <SID>HighlightGroups()<CR>

" open netrw
nnoremap <leader>, :call ToggleFileTree()<CR>

" ------------------------
" 3. navigation and search
" ------------------------

" enable mouse mode
set mouse=a

if !has('nvim')
  set ttymouse=xterm2
endif

" lower escape key delay
set timeoutlen=1000
set ttimeoutlen=10

" use common backspace behavior
set backspace=indent,eol,start

" send more characters at once
set ttyfast

" wrap to previous/next line wit hjkl
set whichwrap=<,>,h,l,[,]

" splits open below and to the right
set splitright
set splitbelow

" return to last cursor position when opening a file
augroup ReturnToPrevCursor
  autocmd!
  autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
augroup end

" add padding while scrolling
set scrolloff=10
set sidescrolloff=10

" always show tab and status bars
set laststatus=2
set showtabline=2

" close location list if parent window closed
augroup LocationList
  autocmd!
  autocmd QuitPre * silent! lclose
augroup end

" grep-style regex
set magic

" use global search by default
set gdefault

" real-time search
set incsearch

" highlight matches
set hlsearch

" ignore case during search
set ignorecase

" completion suggestions
set omnifunc=syntaxcomplete#Complete
set completeopt=menu

" ---------------------------------
" 4. text, indentation, and folding
" ---------------------------------

" work with system clipboard
if has('clipboard')
  set clipboard=unnamedplus
end

" spaces instead of tabs
set tabstop=2
set softtabstop=0
set expandtab
set shiftwidth=2
set smarttab

" filetype-specific indentation
augroup FileTypeIndent
  autocmd!
  autocmd FileType markdown setlocal shiftwidth=4 softtabstop=4
augroup end

" auto indentation
set autoindent
set smartindent

" word wrapping
set wrap
set textwidth=0
set wrapmargin=0
set linebreak

" max number of folds
set foldnestmax=10

" language-specific folding
set foldmethod=indent

" display fold info
set foldcolumn=4

" open folds when reading file
set nofoldenable
set foldlevelstart=99

" enable spellcheck in certain files
augroup SpellCheck
  autocmd!
  autocmd BufRead,BufNewFile *.md,*.markdown,*.txt setlocal spell spelllang=en_us
augroup end

" -------------
" 5. appearance
" -------------

" truecolor support
if has('termguicolors')
  set termguicolors
endif

" preview command results before committing (for example find/replace)
if has('nvim')
  set inccommand=split
endif

" netrw file browser
let g:netrw_banner=0
let g:netrw_liststyle=3
let g:netrw_browse_split=4
let g:netrw_altv=1
let g:netrw_winsize=25
let g:netrw_list_hide=&wildignore

augroup netrw_remap
  autocmd!
  autocmd filetype netrw call NetrwRemap()
augroup END

" command window height
set cmdheight=1

" syntax highlighting
syntax enable

" dark background
set background=dark

" show marker at 120 line length
set colorcolumn=120

" show current command at bottom-right
set showcmd

" always show sign column
set signcolumn=yes

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

" highlight matching braces
set showmatch
set matchtime=2

" don't warn about abandoned buffers
set hidden

" no concealing characters
set conceallevel=0

" don't pass messages to completion menu
set shortmess+=c

" override default highlighting for certain files
augroup RecognizeFiles
  autocmd!
  autocmd BufRead,BufNewFile,BufFilePre .{artilleryrc,babelrc,eslintrc,jsdocrc,nycrc,stylelintrc,markdownlintrc,parcelrc,tern-project,tern-config} set filetype=json
  autocmd BufRead,BufNewFile,BufFilePre *.home set filetype=json  " higharc
  autocmd BufRead,BufNewFile,BufFilePre Procfile,.prettierrc,.commitlintrc set filetype=yaml
  autocmd BufRead,BufNewFile,BufFilePre .{flake8,licenser,flowconfig} set filetype=dosini
  autocmd BufRead,BufNewFile,BufFilePre *.conf set filetype=dosini
  autocmd BufRead,BufNewFile,BufFilePre .tmux.conf set filetype=tmux
  autocmd BufRead,BufNewFile,BufFilePre .{sequelizerc,jestconfig,fxrc} set filetype=javascript
  autocmd BufRead,BufNewFile,BufFilePre *.jsx,*.tsx set filetype=typescriptreact
  autocmd BufRead,BufNewFile,BufFilePre .env.* set filetype=sh
  autocmd BufRead,BufNewFile,BufFilePre *.service set filetype=systemd
augroup end

" force full highlighting for large files using JSX
augroup HighlightFiles
  autocmd!
  autocmd BufEnter *.{js,jsx,ts,tsx} :syntax sync fromstart
  autocmd BufLeave *.{js,jsx,ts,tsx} :syntax sync clear
augroup end

" --------------------
" 6. files and backups
" --------------------

" lower time to write to swap
set updatetime=100

" no swaps and backups
set nobackup
set nowritebackup
set noswapfile

" persistent undo
set undofile
set undodir=~/.vim/undo

" don't change current directory automatically
set noautochdir

" support comments in .json files
augroup JsonComments
  autocmd!
  autocmd FileType json syntax match Comment +\/\/.\+$+
augroup end

" filename completion
if has('wildmenu')
  " ignore case
  set wildignorecase

  " ignore some filetypes
  set wildignore+=*.a,*.o
  set wildignore+=*.pyc,*.egg
  set wildignore+=*.class,*.jar
  set wildignore+=.DS_Store,.Trashes,.Spotlight-V100
  set wildignore+=.git,.svn,.hg

  " enable menu
  set wildmenu
  set wildmode=longest:full,full
endif

" -------------------
" 7. helper functions
" -------------------

" coc current function
function! CocCurrentFunction()
  return get(b:, 'coc_current_function', '')
endfunction

" coc diagnostics
function! StatusDiagnostic() abort
  let info=get(b:, 'coc_diagnostic_info', {})

  if empty(info) | return '' | endif

  let msgs=[]

  if get(info, 'error', 0)
    call add(msgs, 'E' . info['error'])
  endif

  if get(info, 'warning', 0)
    call add(msgs, 'W' . info['warning'])
  endif

  return join(msgs, ' '). ' ' . get(g:, 'coc_status', '')
endfunction

" show highlight groups applied to current text
function! <SID>HighlightGroups()
  if !exists('*synstack')
    return
  endif

  echo map(synstack(line('.'), col('.')), "synIDattr(v:val, 'name')")
endfunction

" toggle netrw and keep it on left side of screen
function! ToggleFileTree()
  if exists("t:expl_buf_num")
    let expl_win_num=bufwinnr(t:expl_buf_num)

    if expl_win_num != -1
      let cur_win_nr=winnr()
      exec expl_win_num . 'wincmd w'
      close
      exec cur_win_nr . 'wincmd w'
      unlet t:expl_buf_num
    else
      unlet t:expl_buf_num
    endif
  else
    exec '1wincmd w'
    Vexplore
    let t:expl_buf_num = bufnr("%")
  endif
endfunction

" netrw-specific remappings
function! NetrwRemap()
  nnoremap <buffer> <C-l> <C-w>l
endfunction

" ----------
" 8. plugins
" ----------

" check for vim-plug config file
let vim_plug_file=expand('~/.vim/autoload/plug.vim')
let gitgutter_plugin=expand('~/.vim/packages/vim-gitgutter')

if !filereadable(vim_plug_file)
  echoerr 'Missing vim-plug config file!'
endif

if filereadable(vim_plug_file)
  call plug#begin('~/.vim/packages')

  " --------------
  " 8a. appearance
  " --------------

  " start screen
  Plug 'mhinz/vim-startify'

  let g:startify_change_to_dir=0
  let g:startify_bookmarks=[
    \ '~/.aliases',
    \ '~/.bashrc',
    \ '~/.config/nvim/coc-settings.json',
    \ '~/.environment',
    \ '~/.exports',
    \ '~/.functions',
    \ '~/.vimrc'
  \ ]

  " color schemes
  Plug 'rafi/awesome-vim-colorschemes'

  " lightline
  Plug 'itchyny/lightline.vim'

  let g:lightline={
    \ 'enable': { 'tabline': 1 },
    \ 'active': {
    \   'left': [
    \     [ 'mode', 'paste', 'spell' ],
    \     [ 'gitbranch', 'readonly', 'relativepath', 'modified' ],
    \     [ 'cocdiagnostic' ]
    \   ],
    \   'right': [
    \     [ 'lineinfo', 'fileformat', 'fileencoding', 'projectindent', 'filetype', 'bufnum' ]
    \   ]
    \ },
    \ 'component_function': {
    \   'projectindent': 'SleuthIndicator',
    \   'cocdiagnostic': 'StatusDiagnostic',
    \   'gitbranch': 'FugitiveHead'
    \ },
  \ }

  " show indent guides
  Plug 'Yggdroot/indentLine'

  let g:indentLine_setConceal=0

  " highlight copied text
  Plug 'machakann/vim-highlightedyank'

  " -------------------------
  " 8b. navigation and search
  " -------------------------

  " find characters on line quicker
  Plug 'unblevable/quick-scope'

  " merge tabs into vertical splits
  Plug 'vim-scripts/Tabmerge'

  nnoremap <leader>tm :execute "Tabmerge left"<CR>

  " sticky scrolling
  Plug 'wellle/context.vim'

  " look up documentation
  Plug 'keith/investigate.vim'

  let g:investigate_use_dash=1

  " navigate between vim and tmux seamlessly
  Plug 'christoomey/vim-tmux-navigator'

  " better find and replace
  Plug 'tpope/vim-abolish'

  " close HTML tags
  Plug 'alvan/vim-closetag'

  let g:closetag_filenames='*.html,*.xhtml,*.phtml,*.xml,*.vue,*.jsx,*.js,*.erb,*.tsx,*.svelte'

  " maximize current pane
  Plug 'szw/vim-maximizer'

  let g:maximizer_set_default_mapping=0
  nnoremap <leader>m :MaximizerToggle!<CR>

  function! GotoWindow(id)
    call win_gotoid(a:id)
    MaximizerToggle
  endfunction

  " -------
  " 8c. git
  " -------

  " git wrapper
  Plug 'tpope/vim-fugitive'

  " github support
  Plug 'tpope/vim-rhubarb'

  " gitlab support
  Plug 'shumphrey/fugitive-gitlab.vim'

  " copy link to current line
  nnoremap <leader>yg :.GBrowse!<CR>

  " show git diff in gutter
  Plug 'airblade/vim-gitgutter'

  " ----------------------
  " 8d. files and projects
  " ----------------------

  " .env file support
  Plug 'tpope/vim-dotenv'

  " fuzzy file search
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

  " close fzf with Esc key
  augroup TermEsc
    if has('nvim')
      autocmd TermOpen * tnoremap <Esc> <c-\><c-n>
      autocmd FileType fzf tunmap <Esc>
    endif
  augroup end

  " make vim project-aware
  Plug 'airblade/vim-rooter'

  let g:rooter_change_directory_for_non_project_files='current'
  let g:rooter_resolve_links=1

  " extend root directories to include vimwiki root
  let g:rooter_patterns=['.git', '_darcs', '.hg', '.bzr', '.svn', 'Makefile', '.wikiroot']

  " add UNIX-like commands
  Plug 'tpope/vim-eunuch'

  " add bookmarks to lines
  Plug 'MattesGroeger/vim-bookmarks'

  " close blocks automatically
  Plug 'tpope/vim-endwise'

  " reload files changed outside of vim
  Plug 'djoshea/vim-autoread'

  " comment out lines quickly
  Plug 'preservim/nerdcommenter'

  let g:NERDSpaceDelims=1
  let g:NERDDefaultAlign='left'
  let g:NERDCommentEmptyLines=1
  let g:NERDTrimTrailingWhitespace=1

  " emoji support
  Plug 'junegunn/vim-emoji'

  " match pairs
  Plug 'jiangmiao/auto-pairs'

  let g:AutoPairsFlyMode=0

  " recognize indent settings per project
  Plug 'tpope/vim-sleuth'

  " man pages
  Plug 'vim-utils/vim-man'

  " -----------
  " 8e. testing
  " -----------

  " debugging
  Plug 'puremourning/vimspector'

  let g:vimspector_install_gadgets=[ 'vscode-node-debug2', 'debugger-for-chrome', 'debugpy', 'vscode-go' ]

  nnoremap <leader>dd :call vimspector#Launch()<CR>
  nnoremap <leader>d<space> :call vimspector#Continue()<CR>
  nnoremap <leader>de :call vimspector#Reset()<CR>

  nnoremap <leader>dc :call GotoWindow(g:vimspector_session_windows.code)<CR>
  nnoremap <leader>dt :call GotoWindow(g:vimspector_session_windows.tagpage)<CR>
  nnoremap <leader>dv :call GotoWindow(g:vimspector_session_windows.variables)<CR>
  nnoremap <leader>dw :call GotoWindow(g:vimspector_session_windows.watches)<CR>
  nnoremap <leader>ds :call GotoWindow(g:vimspector_session_windows.stack_trace)<CR>
  nnoremap <leader>do :call GotoWindow(g:vimspector_session_windows.output)<CR>

  nmap <leader>dl <Plug>VimspectorStepInto
  nmap <leader>dj <Plug>VimspectorStepOver
  nmap <leader>dk <Plug>VimspectorStepOut
  nmap <leader>d_ <Plug>VimspectorRestart

  nmap <leader>dr <Plug>VimspectorRunToCursor
  nmap <leader>db <Plug>VimspectorToggleBreakpoint
  nmap <leader>dcb <Plug>VimspectorToggleConditionalBreakpoint

  " run tests
  Plug 'janko-m/vim-test'
  Plug 'tpope/vim-dispatch'

  nnoremap <leader>t :TestFile<CR>
  nnoremap <leader>T :TestNearest<CR>

  let test#strategy='dispatch'

  " language-specific test settings
  let test#ruby#minitest#file_pattern='\.test\.rb'

  " -------------
  " 8f. languages
  " -------------

  " coffeescript
  Plug 'kchmck/vim-coffee-script'

  " css
  Plug 'vim-language-dept/css-syntax.vim'
  Plug 'ap/vim-css-color'

  " csv
  Plug 'chrisbra/csv.vim'

  let g:csv_delim=','
  let g:csv_nomap_cr=1
  let g:csv_nomap_space=1
  let g:csv_nomap_bs=1

  " graphql
  Plug 'jparise/vim-graphql'

  " golang
  Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }

  let g:go_def_mapping_enabled=0

  " graphviz
  Plug 'wannesm/wmgraphviz.vim'

  " jenkins
  Plug 'martinda/Jenkinsfile-vim-syntax'

  " json
  Plug 'elzr/vim-json'

  let g:vim_json_syntax_conceal=0

  " javascript/typescript/react/svelte
  Plug 'pangloss/vim-javascript'
  Plug 'leafgarland/typescript-vim'
  Plug 'peitalin/vim-jsx-typescript'
  Plug 'chemzqm/vim-jsx-improve'
  Plug 'styled-components/vim-styled-components', { 'branch': 'main' }
  Plug 'prettier/vim-prettier', { 'do': 'npm install' }
  Plug 'evanleck/vim-svelte', { 'branch': 'main' }

  let g:javascript_plugin_jsdoc=1
  let g:javascript_plugin_flow=1

  " latex
  Plug 'lervag/vimtex'

  let g:tex_flavor='latex'

  if has('nvim')
    let g:vimtex_compiler_progname='nvr'
  end

  " lisp
  Plug 'vlime/vlime', { 'rtp': 'vim/' }

  " markdown / mdx
  Plug 'plasticboy/vim-markdown'
  Plug 'jxnblk/vim-mdx-js'

  let g:vim_markdown_conceal=0
  let g:vim_markdown_new_list_item_indent=4
  let g:vim_markdown_fenced_languages=[
    \ 'bash=sh',
    \ 'c++=cpp',
    \ 'cs=csharp',
    \ 'js=javascript',
    \ 'jsx=javascriptreact',
    \ 'rb=ruby',
    \ 'ini=dosini',
    \ 'viml=vim',
    \ 'tsx=typescriptreact',
  \ ]

  " nginx
  Plug 'chr4/nginx.vim'

  " php / blade
  Plug 'jwalton512/vim-blade'

  " prisma
  Plug 'pantharshit00/vim-prisma'

  " python
  Plug 'vim-python/python-syntax'

  let g:python_highlight_all=1

  " ruby
  Plug 'vim-ruby/vim-ruby'
  Plug 'tpope/vim-rails'
  Plug 'tpope/vim-bundler'
  Plug 'asux/vim-capybara'

  Plug 'hashivim/vim-terraform'

  let g:terraform_align=1
  let g:terraform_fold_sections=1
  let g:terraform_fmt_on_save=1

  " sql
  Plug 'tpope/vim-dadbod' " also required for coc-db to work
  Plug 'kristijanhusak/vim-dadbod-ui'

  let g:db_ui_save_location=expand('~/.vimdb')

  nnoremap <leader>D :DBUI<CR>

  " toml
  Plug 'cespare/vim-toml'

  " vimscript
  Plug 'junegunn/vader.vim'

  " vue
  Plug 'posva/vim-vue'

  " fix for vue highlighting
  augroup VueHighlight
    autocmd!
    autocmd FileType vue syntax sync fromstart
  augroup end

  " ------------------------------
  " 8g. autocompletion and linting
  " ------------------------------

  " coc provides vscode-esque completion
  Plug 'neoclide/coc.nvim', { 'branch': 'release' }

  let g:coc_global_extensions=[
    \ 'coc-css',
    \ 'coc-db',
    \ 'coc-diagnostic',
    \ 'coc-dictionary',
    \ 'coc-emoji',
    \ 'coc-eslint',
    \ 'coc-json',
    \ 'coc-markdownlint',
    \ 'coc-marketplace',
    \ 'coc-prettier',
    \ 'coc-prisma',
    \ 'coc-pyright',
    \ 'coc-solargraph',
    \ 'coc-sql',
    \ 'coc-stylelintplus',
    \ 'coc-svelte',
    \ 'coc-tsserver',
    \ 'coc-vimlsp',
    \ 'coc-word',
  \ ]

  let g:coc_filetype_map = {
    \ 'vimwiki': 'markdown',
  \ }

  " use enter to accept selected completion item or notify coc.nvim to format
  inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
    \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

  " use <C-d> and <C-S-d> to navigate warnings and errors
  nmap <silent> <C-d> <Plug>(coc-diagnostic-next)
  nmap <silent> <C-S-d> <Plug>(coc-diagnostic-prev)

  " code navigation
  nmap <silent> gd <Plug>(coc-definition)
  nmap <silent> gs :call CocAction('jumpDefinition', 'vsplit')<CR>
  nmap <silent> gS :call CocAction('jumpDefinition', 'tab drop')<CR>
  nmap <silent> gy <Plug>(coc-type-definition)
  nmap <silent> gi <Plug>(coc-implementation)
  nmap <silent> gr <Plug>(coc-references)

  " use K to show documentation in preview window
  nnoremap <silent> H :call <SID>show_documentation()<CR>

  function! s:show_documentation()
    if (index([ 'vim','help' ], &filetype) >= 0)
      execute 'h '.expand('<cword>')
    else
      call CocAction('doHover')
    endif
  endfunction

  " ---------
  " 8h. misc.
  " ---------

  " standardize vim/neovim async api
  Plug 'prabirshrestha/async.vim'

  " todoist integration
  Plug 'romgrk/todoist.nvim', { 'do': ':TodoistInstall' }

  " better writing habits
  Plug 'reedes/vim-wordy'

  " session management
  Plug 'tpope/vim-obsession'

  " wiki
  Plug 'vimwiki/vimwiki'

  let g:vimwiki_create_link=0
  let g:vimwiki_global_ext=0
  let g:vimwiki_listsyms='✗○◐●✓'
  let g:vimwiki_list=[
    \ {
      \ 'path': '/run/media/tylucaskelley/Storage/Dropbox/Files/notes',
      \ 'syntax': 'markdown',
      \ 'ext': '.md',
      \ 'nested_syntaxes': {
        \ 'cs': 'csharp',
        \ 'c++': 'cpp',
        \ 'bash': 'sh',
        \ 'viml': 'vim',
        \ 'rb': 'ruby',
        \ 'js': 'javascript',
        \ 'ini': 'dosini'
      \ }
    \ }
  \ ]

  " shortcut for navigating to important notes directories
  command! Notes VimwikiIndex
  command! Diary VimwikiDiaryIndex

  " open notes in small vertical split
  nnoremap <leader>N :80vs<BAR> :Notes<CR>

  augroup VimWikiSettings
      autocmd!

      " use 120 textwidth for vimwiki files for easy reformatting
      autocmd FileType vimwiki setlocal textwidth=120

      " 4 space indent
      autocmd FileType vimwiki setlocal shiftwidth=4 softtabstop=4

      " automatically update links when reading diary index page
      autocmd BufRead,BufNewFile diary.md VimwikiDiaryGenerateLinks

      " keep my original keymappings for some commands
      autocmd FileType vimwiki nnoremap <buffer> <Tab> /
      autocmd FileType vimwiki nnoremap <buffer> <CR> :noh<CR><CR>

      " vimwiki commands
      autocmd FileType vimwiki nnoremap <buffer> wh :VimwikiIndex<CR>
      autocmd FileType vimwiki nnoremap <buffer> wd :VimwikiDiaryIndex<CR>
      autocmd FileType vimwiki nnoremap <buffer> wf :VimwikiFollowLink<CR>
      autocmd FileType vimwiki nnoremap <buffer> ws :VimwikiVSplitLink<CR>

      " customize syntax regions
      autocmd FileType vimwiki syntax region VimwikiBlockquote start=/^\s*>/ end="$"

      " change hightlight groups
      autocmd FileType vimwiki highlight link VimwikiBlockquote mkdBlockquote
  augroup end

  call plug#end()

  " ------------------------------------------------
  " settings that come after vim-plug initialization
  " ------------------------------------------------

  " vim-emoji: use emojis with vim-gitgutter plugin
  if isdirectory(gitgutter_plugin)
    let g:gitgutter_sign_added=emoji#for('small_blue_diamond')
    let g:gitgutter_sign_modified=emoji#for('small_orange_diamond')
    let g:gitgutter_sign_removed=emoji#for('small_red_triangle')
    let g:gitgutter_sign_modified_removed=emoji#for('collision')
  endif

  " set colorscheme
  try
    colorscheme gruvbox
    let g:lightline.colorscheme='gruvbox'
  catch
    colorscheme ron
  endtry
endif

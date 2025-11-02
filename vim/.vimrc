" Basic settings
set nocompatible
set encoding=utf-8

" Handler cursor shape changes
set guicursor=
let &t_SI = "\e[6 q"  " Line cursor for insert mode
let &t_EI = "\e[2 q"  " Block cursor for normal mode
let &t_SR = "\e[4 q"  " Underline cursor for replace mode
autocmd VimEnter * silent !echo -ne "\e[2 q"
autocmd InsertEnter * silent !echo -ne "\e[6 q"
autocmd InsertLeave * silent !echo -ne "\e[2 q"

set hidden
set number
set ignorecase
set smartcase
set incsearch
set hlsearch
set autoindent
set smartindent
set expandtab
set tabstop=2
set shiftwidth=2
set softtabstop=2
set backspace=indent,eol,start
set clipboard=unnamedplus
set mouse=a

" Additional display settings
set numberwidth=2
set ruler
set splitbelow
set splitright
set background=dark
set scrolloff=10
set synmaxcol=300
set redrawtime=10000
set timeoutlen=300
set whichwrap+=<,>,[,],h,l

" Hide ~ characters on empty lines
set fillchars=eob:\

" Smooth scrolling for wrapped lines
noremap j gj
noremap k gk
noremap <Down> gj
noremap <Up> gk

" Visual mode smooth scrolling
vnoremap j gj
vnoremap k gk
vnoremap <Down> gj
vnoremap <Up> gk

" Visual line mode smooth scrolling
xnoremap j gj
xnoremap k gk

" Delete without copying to register
nnoremap x "_x

" Better paste in visual mode (without overwriting register)
vnoremap p p:let @+=@0<CR>:let @"=@0<CR>
xnoremap p p:let @+=@0<CR>:let @"=@0<CR>

" Better indentation in visual mode (keep selection)
vnoremap < <gv
vnoremap > >gv

" Disable space key default behavior
nnoremap <Space> <Nop>
vnoremap <Space> <Nop>

" Smooth wrapped line navigation 
noremap <expr> j (v:count == 0 ? 'gj' : 'j')
noremap <expr> k (v:count == 0 ? 'gk' : 'k')
noremap <expr> <Down> (v:count == 0 ? 'gj' : 'j')
noremap <expr> <Up> (v:count == 0 ? 'gk' : 'k')

" Visual mode wrapped line navigation
vnoremap <expr> j (v:count == 0 ? 'gj' : 'j')
vnoremap <expr> k (v:count == 0 ? 'gk' : 'k')
vnoremap <expr> <Down> (v:count == 0 ? 'gj' : 'j')
vnoremap <expr> <Up> (v:count == 0 ? 'gk' : 'k')

" Visual line mode wrapped line navigation
xnoremap <expr> j (v:count == 0 ? 'gj' : 'j')
xnoremap <expr> k (v:count == 0 ? 'gk' : 'k')

" Performance settings
set lazyredraw
set ttyfast
set updatetime=300

" Better undo
set undofile
set undolevels=1000
set undoreload=10000

" Performance optimizations
set history=1000

" Optimize grep command for better performance
if executable('rg')
  set grepprg=rg\ --vimgrep\ --smart-case\ --follow
endif

" Search improvements
set wildmenu
set wildmode=longest:full,full
set wildignore+=*/node_modules/*,*/.git/*,*/dist/*,*/build/*,*/vendor/*
set wildignore+=*.o,*.a,*.out,*.class,*.pdf,*.mkv,*.mp4,*.zip
set wildignore+=*.png,*.jpg,*.jpeg,.DS_Store,*.res,*.mp3,*.ttf,*.otf

" Status line
set laststatus=2
set showcmd
set noshowmode

" File operations
nnoremap <C-s> :w<CR>
nnoremap <C-c> :%y+<CR>

" Clear search highlights
nnoremap <Esc> :noh<CR>

" Window management
nnoremap <leader>sv <C-w>v
nnoremap <leader>sh <C-w>s
nnoremap <leader>se <C-w>=
nnoremap <leader>sx :close<CR>

" Tab management
nnoremap <leader>to :tabnew<CR>
nnoremap <leader>tx :tabclose<CR>
nnoremap <leader>tn :tabn<CR>
nnoremap <leader>tp :tabp<CR>
nnoremap <leader>tf :tabnew %<CR>

" Active buffer management
nnoremap <Tab> :bnext<CR>
nnoremap <S-Tab> :bprev<CR>
nnoremap <leader>x :bdelete<CR>

" Insert mode navigation
inoremap <C-h> <Left>
inoremap <C-l> <Right>
inoremap <C-j> <Down>
inoremap <C-k> <Up>
inoremap <C-b> <Esc>^i
inoremap <C-e> <End>
inoremap jj <Esc>

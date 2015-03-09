" Use Vim settings, rather than Vi settings (much better!).
" This must be first, because it changes other options as a side effect.
set nocompatible
filetype off   "this is for vundle, I turn it back on later

"scriptendcoding utf-8
set encoding=utf-8
"set timeoutlen=250

set visualbell t_vb=
set noerrorbells

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" required for vundle to mangage vundle
Plugin 'gmarik/Vundle.vim'

" My plugins
Plugin 'scrooloose/syntastic'
Plugin 'scrooloose/nerdtree'
Plugin 'scrooloose/nerdcommenter'
Plugin 'bling/vim-airline'
Plugin 'Valloric/YouCompleteMe'
Plugin 'tpope/vim-surround'
Plugin 'jelera/vim-javascript-syntax'
Plugin 'kien/ctrlp.vim'

"molokai
"let g:molokai_original = 1
"let g:rehash256 = 1

"NERDTree
map <leader>nn :NERDTreeToggle<CR>


"syntastic
nnoremap <Leader>ss :SyntasticToggleMode<CR>
nnoremap <silent> <leader>ln :lnext<cr>
nnoremap <silent> <leader>lp :lprevious<cr>
nnoremap <silent> <leader>lc :lclose<cr>
nnoremap <silent> <leader>lo :lopen<cr>

set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

let g:syntastic_python_checkers = ['flake8']
let g:syntastic_javascript_checkers = ['jshint']
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_wq = 0

" For airline plugin
if !exists('g:airline_symbols')
  let g:airline_symbols = {}
endif

" unicode symbols
let g:airline_left_sep = ''
let g:airline_right_sep = ''
let g:airline_symbols.linenr = '¶'
let g:airline_symbols.branch = '⎇'                         
let g:airline_symbols.paste = 'ρ'
let g:airline_symbols.whitespace = 'Ξ' 
let g:airline#extensions#whitespace#enabled=0
let g:airline#extensions#tabline#enabled=1
let g:airline#extensions#tabline#fnamemod=':t'
set laststatus=2 
            
" For YouCompleteMe
let g:ycm_global_ycm_extra_conf = '~/.vim/.ycm_extra_conf.py'
"turn on and off YouCompleteMe 
nnoremap <leader>ycm :call YCMToggle()<cr>
           
function! YCMToggle()
    if g:ycm_auto_trigger
        let g:ycm_auto_trigger=0
    else                       
        let g:ycm_auto_trigger=1
    endif
endfunction


call vundle#end()
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line


" map space bar to the <Leader>
map <Space> <Leader>

" CTRL-U in insert mode deletes a lot.  Use CTRL-G u to first break undo,
" so that you can undo CTRL-U after inserting a line break.
inoremap <C-U> <C-G>u<C-U>

" In many terminal emulators the mouse works just fine, thus enable it.
if has('mouse')
  set mouse=a
endif

" Switch syntax highlighting on, when the terminal has colors
if &t_Co > 2 || has("gui_running")
  syntax on
endif

" Enable file type detection.
" Also load indent files, to automatically do language-dependent indenting.
filetype on
filetype plugin on
filetype plugin indent on

" Only do this part when compiled with support for autocommands.
if has("autocmd")


  " Put these in an autocmd group, so that we can delete them easily.
  augroup vimrcEx
  au!

  " When editing a file, always jump to the last known cursor position.
  " Don't do it when the position is invalid or when inside an event handler
  " (happens when dropping a file on gvim).
  " Also don't do it when the mark is in the first line, that is the default
  " position when opening a file.
  autocmd BufReadPost *
    \ if line("'\"") > 1 && line("'\"") <= line("$") |
    \   exe "normal! g`\"" |
    \ endif
  augroup END

endif " has("autocmd")

" Convenient command to see the difference between the current buffer and the
" file it was loaded from, thus the changes you made.
" Only define it when not defined already.
if !exists(":DiffOrig")
  command DiffOrig vert new | set bt=nofile | r # | 0d_ | diffthis
		  \ | wincmd p | diffthis
endif 

" Tells you what mode you are in
set showmode
set showcmd

" move windows easily
map <C-J> <C-W>j
map <C-K> <C-W>k
map <C-H> <C-W>h
map <C-L> <C-W>l

"copy to system clipboard with leader key
vmap <Leader>y "+y
vmap <Leader>d "+d
vmap <Leader>p "+p
vmap <Leader>P "+P

nmap <Leader>p "+p
nmap <Leader>P "+P
nmap <Leader>y "+y
nmap <Leader>d "+d

" Enables enhanced command-line completion. Presumes you have compiled
" with +wildmenu. See :help 'wildmenu'
"set wildmenu

" Make it easy to edit vimrc
" Think 'e'dit 'v'imrc
nmap <silent> ,ev :e $MYVIMRC<cr>

" Set the search scan to wrap around the file
set wrapscan

" Make command line two lines high
set ch=2

" Allow backspacing over indent, eol, and the start of an insert
set backspace=2

" Keeps some history
set history=100

" When the page starts to scroll, keep the cursor 4 lines from the
" top and 4 lines from the bottom
set scrolloff=4

" Allow the cursor to go to areas beyong the line
set virtualedit=all

" Tabstops are 4 spaces
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab
set autoindent


" Set up the gui cursor to look nice
set guicursor=n-v-c:block-Cursor-blinkon0,ve:ver35-Cursor,o:hor50-Cursor,i-ci:ver25-Cursor,r-cr:hor20-Cursor,sm:block-Cursor-blinkwait175-blinkoff150-blinkon175

" Set the textwidth to be 0 chars
set textwidth=100

" Enable search highlighting
set hlsearch
" spacebar turns of highlight
:nnoremap <silent> <Leader>/ :nohlsearch<Bar>:echo<CR> 
" do not require case sensitivity in search
set ignorecase
" Incrementally match the search
set incsearch                  

" lets ii get you out of insert mode
imap ii <Esc>

" Trying out the line numbering thing... never liked it, but that doesn't mean
" I shouldn't give it another go :)
set number

" Wasted stuff here
set nobackup
set noswapfile

" Press this before right-click-pasting something
set pastetoggle=<F2>

" Lets Vim know that it can use 256 colors
set t_Co=256
"colorscheme wombat256mod
colorscheme molokai
" Set the colorscheme in python -- as darkspectrum is good for c++
" autocmd FileType python colorscheme wombat

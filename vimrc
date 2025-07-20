" Use Vim settings, rather than Vi settings (much better!).
" This must be first, because it changes other options as a side effect.
set nocompatible
filetype off   "this is for vundle, I turn it back on later

"scriptendcoding utf-8
set encoding=utf-8
"set timeoutlen=250

set visualbell t_vb=
set noerrorbells
set novisualbell
set belloff=all

"nvim-tree (modern replacement for NERDTree)
map <leader>nn :NvimTreeToggle<CR>


" vimwiki/vimwiki
let g:vimwiki_list = [{'path': '~/vimwiki/', 'syntax': 'markdown', 'ext': '.md'}]

" map space bar to the <Leader>
map <Space> <Leader>

" map ; to : make easy commands yo
map ; :

" F2 saves your session (tabs, buffers etc) F3 restores
map <F2> :mksession! ~/.vim_session <cr> " Quick write session with F2
map <F3> :source ~/.vim_session <cr>     " And load session with F3

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

" Configre tabs. Tabs convert to spaces
set tabstop=2
set shiftwidth=2
set softtabstop=2
set expandtab
set autoindent

" Python stuff
au BufNewFile,BufRead *.py setlocal tabstop=4 shiftwidth=4 softtabstop=4

" C++ stuff
au BufNewFile,BufRead *.cpp setlocal tabstop=4 shiftwidth=4 softtabstop=4
au BufNewFile,BufRead *.hpp setlocal tabstop=4 shiftwidth=4 softtabstop=4

" Javascript stuff
au BufNewFile,BufRead *.ejs,*.hbs setlocal filetype=html

" Only do this part when compiled with support for autocommands.
if has("autocmd")

  " remove trailing whitespace for these languages
  "autocmd FileType c,cpp,hpp,java,javascript,php,ruby,python autocmd BufWritePre <buffer> :%s/\s\+$//e

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
vmap <Leader>x "+x

nmap <Leader>p "+p
nmap <Leader>P "+P
nmap <Leader>y "+y
nmap <Leader>d "+d
nmap <Leader>x "+x

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

" Set up the gui cursor to look nice
set guicursor=n-v-c:block-Cursor-blinkon0,ve:ver35-Cursor,o:hor50-Cursor,i-ci:ver25-Cursor,r-cr:hor20-Cursor,sm:block-Cursor-blinkwait175-blinkoff150-blinkon175

" Set the textwidth to be 0 chars
set textwidth=100

" Enable search highlighting
set hlsearch
" leader / turns of highlight
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

" Lets Vim know that it can use 256 colors
set t_Co=256
set termguicolors
set background=dark
" Use onedark colorscheme (matching Neovim) if available, fallback to molokai
try
  colorscheme onedark
catch /^Vim\%((\a\+)\)\=:E185/
  colorscheme molokai
endtry

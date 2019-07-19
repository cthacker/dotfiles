" ============================================================================ "
" ===                               PLUGINS                                === "
" ============================================================================ "

" check whether vim-plug is installed and install it if necessary
let plugpath = expand('<sfile>:p:h'). '/autoload/plug.vim'
if !filereadable(plugpath)
    if executable('curl')
        let plugurl = 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
        call system('curl -fLo ' . shellescape(plugpath) . ' --create-dirs ' . plugurl)
        if v:shell_error
            echom "Error downloading vim-plug. Please install it manually.\n"
            exit
        endif
    else
        echom "vim-plug not installed. Please install it manually or install curl.\n"
        exit
    endif
endif

call plug#begin('~/.config/nvim/plugged')

" === Editing Plugins === "
" Trailing whitespace highlighting & automatic fixing
Plug 'ntpeters/vim-better-whitespace'

" Wiki
Plug 'vimwiki/vimwiki'     

" needed for vimwiki
Plug 'godlygeek/tabular'

" Every syntax highlight known to man
Plug 'sheerun/vim-polyglot'

" auto-close plugin
Plug 'rstacruz/vim-closer'
  
" quick comment/uncomment lines
Plug 'scrooloose/nerdcommenter'

" Intellisense Engine
Plug 'neoclide/coc.nvim', {'do': 'yarn install --frozen-lockfile'}
"Plug 'neoclide/coc.nvim', {'tag': '*', 'branch': 'release'}
"Plug 'neoclide/coc.nvim', {'do': { -> coc#util#install()}}
                     
" ctrl-j etc to move tmux panes or vim splits
Plug 'christoomey/vim-tmux-navigator'
 
" Fuzzy finder
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'

" Print function signatures in echo area
"Plug 'Shougo/echodoc.vim'

" === Javascript Plugins === "
" Typescript syntax highlighting
"Plug 'HerringtonDarkholme/yats.vim'

" ReactJS JSX syntax highlighting
"Plug 'mxw/vim-jsx'

" === Syntax Highlighting === "

" === UI === "
" File explorer
Plug 'scrooloose/nerdtree'

" Colorscheme
Plug 'mhartington/oceanic-next'
Plug 'w0ng/vim-hybrid'
Plug 'ayu-theme/ayu-vim'

" Customized vim status line
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" Icons
Plug 'ryanoasis/vim-devicons'
Plug 'tiagofumo/vim-nerdtree-syntax-highlight'

" Initialize plugin system
call plug#end()

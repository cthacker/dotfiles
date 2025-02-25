scriptencoding utf-8
source ~/.config/nvim/plugins.vim
source ~/.vimrc

" === General Settings === "
set cmdheight=2
set updatetime=300
set shortmess+=c
set signcolumn=yes

" === Airline Configuration === "
let g:airline_extensions = ['branch', 'hunks']
let g:airline_section_z = airline#section#create(['linenr'])
let g:airline_skip_empty_sections = 1
let g:airline#extensions#tabline#formatter = 'unique_tail'
let g:airline#extensions#default#layout = [['a', 'b', 'c'], ['x', 'z', 'warning', 'error']]
let g:airline_exclude_preview = 1
let g:airline_powerline_fonts = 1
let g:airline_highlighting_cache = 1

" Define custom airline symbols
if !exists('g:airline_symbols')
  let g:airline_symbols = {}
endif

" === NERDTree Configuration === "
let g:NERDTreeStatusline = ''
let g:NERDTreeShowHidden = 1
nnoremap <leader>nn :NERDTreeToggle<CR>

" === FZF Configuration === "
nnoremap <c-p> :Files<CR>

" === Load Lua Configuration === "
lua << EOF
-- Load LSP configuration
require('user.lsp')

-- Load Telescope configuration
require('user.telescope')
EOF

" === Telescope Mappings === "
nnoremap <leader>ff <cmd>Telescope find_files<CR>
nnoremap <leader>fg <cmd>Telescope live_grep<CR>
nnoremap <leader>fb <cmd>Telescope buffers<CR>
nnoremap <leader>fh <cmd>Telescope help_tags<CR>

" === LSP Compatibility Mappings === "
" These maintain compatibility with your previous CoC key mappings
nmap <silent> <leader>ld <cmd>lua vim.lsp.buf.definition()<CR>
nmap <silent> <leader>lt <cmd>lua vim.lsp.buf.type_definition()<CR>
nmap <silent> <leader>li <cmd>lua vim.lsp.buf.implementation()<CR>
nmap <silent> <leader>lf <cmd>lua vim.lsp.buf.references()<CR>
nmap <leader>lr <cmd>lua vim.lsp.buf.rename()<CR>
nnoremap <silent> K <cmd>lua vim.lsp.buf.hover()<CR>

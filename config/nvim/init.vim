scriptencoding utf-8
source ~/.vimrc

" This is a transitional file to help with migration to init.lua
" If init.lua exists, use that instead
if filereadable(expand('~/.config/nvim/init.lua'))
  lua << EOF
  -- Import configured Lua modules if they exist
  local status_ok, _ = pcall(require, "user.lsp")
  if not status_ok then
    vim.notify("LSP configuration not found", vim.log.levels.WARN)
  end
  
  local status_ok, _ = pcall(require, "user.telescope")
  if not status_ok then
    vim.notify("Telescope configuration not found", vim.log.levels.WARN)
  end
EOF

" Set up Telescope mappings
nnoremap <leader>ff <cmd>Telescope find_files<CR>
nnoremap <leader>fg <cmd>Telescope live_grep<CR>
nnoremap <leader>fb <cmd>Telescope buffers<CR>
nnoremap <leader>fh <cmd>Telescope help_tags<CR>
nnoremap <c-p> <cmd>Telescope find_files<CR>

" Set up NvimTree mappings
nnoremap <leader>nn <cmd>NvimTreeToggle<CR>
nnoremap <leader>nf <cmd>NvimTreeFindFile<CR>

" LSP Keymappings
nmap <silent> <leader>ld <cmd>lua vim.lsp.buf.definition()<CR>
nmap <silent> <leader>lt <cmd>lua vim.lsp.buf.type_definition()<CR>
nmap <silent> <leader>li <cmd>lua vim.lsp.buf.implementation()<CR>
nmap <silent> <leader>lf <cmd>lua vim.lsp.buf.references()<CR>
nmap <leader>lr <cmd>lua vim.lsp.buf.rename()<CR>
nnoremap <silent> K <cmd>lua vim.lsp.buf.hover()<CR>

" Try to use Onedark theme for consistency
try
  colorscheme onedark
catch /^Vim\%((\a\+)\)\=:E185/
  " Fallback to molokai if onedark isn't available
  colorscheme molokai
endtry
endif

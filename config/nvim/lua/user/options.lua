-- Neovim-only options. Shared settings (search, numbers, mouse, colors, cmdheight,
-- scrolloff, per-filetype indentation, ...) live in vimrc, which init.lua sources
-- first; only set something here when it doesn't apply to Vim or must differ.

local opt = vim.opt

-- Tabs & Indentation (vimrc leaves Vim on its defaults)
opt.tabstop = 2
opt.shiftwidth = 2
opt.softtabstop = 2
opt.expandtab = true
opt.smartindent = true
opt.wrap = false

-- Search
opt.smartcase = true

-- Appearance
opt.signcolumn = "yes"
opt.completeopt = "menuone,noselect"
opt.showmode = false -- lualine already shows the mode

-- Behavior
opt.splitright = true
opt.splitbelow = true
opt.clipboard = "unnamedplus"

-- Decrease update time
opt.updatetime = 250
opt.timeoutlen = 300

-- No remote-plugin hosts: nothing here uses Python/Node/Ruby/Perl plugins, and
-- LSP servers are installed and run by mason, not through these providers.
vim.g.loaded_python3_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0

-- Remove trailing whitespace on save
vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("TrimWhitespace", { clear = true }),
  command = [[%s/\s\+$//e]],
})

-- General Neovim options and settings

local opt = vim.opt
local g = vim.g

-- Leader key
g.mapleader = " "
g.maplocalleader = " "

-- Line numbers
opt.number = true
opt.relativenumber = true

-- Tabs & Indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.softtabstop = 2
opt.expandtab = true
opt.smartindent = true
opt.autoindent = true
opt.wrap = false

-- Search settings
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true

-- Appearance
opt.termguicolors = true
opt.background = "dark"
opt.signcolumn = "yes"
opt.cmdheight = 1
opt.scrolloff = 10
opt.completeopt = "menuone,noselect"

-- Behavior
opt.hidden = true
opt.errorbells = false
opt.swapfile = false
opt.backup = false
opt.undofile = true
opt.undodir = vim.fn.expand("~/.vim/undodir")
opt.backspace = "indent,eol,start"
opt.splitright = true
opt.splitbelow = true
opt.autochdir = false
opt.mouse = "a"
opt.clipboard = "unnamedplus"
opt.modifiable = true
opt.encoding = "UTF-8"
opt.showmode = false

-- Decrease update time
opt.updatetime = 250
opt.timeoutlen = 300

-- File type specific indentation
vim.cmd([[
  augroup FileTypeSpecificIndentation
    autocmd!
    autocmd FileType python setlocal tabstop=4 shiftwidth=4 softtabstop=4
    autocmd FileType cpp,c,h,hpp setlocal tabstop=4 shiftwidth=4 softtabstop=4
  augroup END
]])

-- Remove trailing whitespace on save
vim.cmd([[
  augroup TrimWhitespace
    autocmd!
    autocmd BufWritePre * :%s/\s\+$//e
  augroup END
]])
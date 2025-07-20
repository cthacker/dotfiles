-- Modern Neovim Configuration
-- Main init file that loads all other configurations

-- Source traditional vimrc for shared settings
vim.cmd('source ~/.vimrc')

-- Core settings and keymaps
require('user.options')  -- General Neovim settings
require('user.keymaps')  -- Key mappings

-- Plugin management with lazy.nvim
require('user.lazy')     -- Plugin manager and plugin definitions

-- Modern Neovim Configuration
-- Main init file that loads all other configurations

-- Core settings and keymaps
require('user.options')  -- General Neovim settings
require('user.keymaps')  -- Key mappings

-- Plugin management with lazy.nvim
require('user.lazy')     -- Plugin manager and plugin definitions

-- Plugin configurations
require('user.lsp')      -- LSP configuration
require('user.telescope') -- Telescope configuration
require('user.treesitter') -- Treesitter for better syntax highlighting
require('user.nvim-tree') -- File explorer
require('user.statusline') -- Status line configuration
require('user.colorscheme') -- Colorscheme configuration (Atom One)
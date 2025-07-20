-- lazy.nvim plugin manager setup
-- Migrated from vim-plug for improved performance and lazy-loading

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Define plugins
local plugins = {
  -- Core plugins
  {
    "nvim-lua/plenary.nvim", -- Lua functions used by many plugins
  },

  -- Colorscheme
  {
    "navarasu/onedark.nvim", -- Atom One Dark theme
    priority = 1000,
    config = function()
      require("onedark").setup({
        style = "dark", -- Choose style: dark, darker, cool, deep, warm, warmer
      })
    end,
  },


  -- Treesitter for better syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
  },

  -- File explorer
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = {
      "nvim-tree/nvim-web-devicons", -- Optional, for file icons
    },
  },

  -- Telescope for fuzzy finding
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
  },

  -- Status line
  {
    "nvim-lualine/lualine.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons", -- Recommended for file type icons
    },
  },

  -- Git integration
  {
    "lewis6991/gitsigns.nvim", -- Git integration for buffers
  },

  -- Autopairs
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
  },

  -- Comments
  {
    "numToStr/Comment.nvim", -- Smart commenting
    event = "BufRead",
  },

  -- Buffer line (tabs)
  {
    "akinsho/bufferline.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
  },

  -- Terminal
  {
    "akinsho/toggleterm.nvim",
  },

  -- Indentation guides
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
  },

  -- Which key for keybinding help
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
  },

  -- Wiki functionality (migrated from vim-plug, settings in vimrc)
  {
    "vimwiki/vimwiki",
  },

  -- Text alignment for tables (needed for vimwiki)
  {
    "godlygeek/tabular",
    cmd = {"Tabularize"},
  },

  -- Tmux integration (migrated from vim-plug)
  {
    "christoomey/vim-tmux-navigator",
    event = "VeryLazy",
  },

  -- Markdown preview (migrated from vim-plug)
  {
    "iamcco/markdown-preview.nvim",
    build = "cd app && yarn install",
    ft = "markdown",
  },

}

-- Load plugins
require("lazy").setup(plugins, {
  install = {
    colorscheme = { "onedark" },
  },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "matchit",
        "matchparen",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
return {
  "nvim-tree/nvim-tree.lua",
  cmd = { "NvimTreeToggle", "NvimTreeFindFile", "NvimTreeOpen", "NvimTreeClose" },
  -- Also load when opening a directory (for `nvim .`)
  init = function()
    vim.api.nvim_create_autocmd("BufEnter", {
      callback = function(args)
        if vim.fn.isdirectory(vim.api.nvim_buf_get_name(args.buf)) == 1 then
          require("nvim-tree.api").tree.open()
        end
      end,
    })
  end,
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    require("nvim-tree").setup({
      disable_netrw = true,
      hijack_netrw = true,
      hijack_directories = {
        enable = true,
        auto_open = true,
      },
      update_focused_file = {
        enable = true,
        update_root = true,
      },
      sort_by = "case_sensitive",
      view = {
        width = 30,
        relativenumber = false,
      },
      renderer = {
        group_empty = true,
        icons = {
          show = {
            file = true,
            folder = true,
            folder_arrow = true,
            git = true,
          },
          glyphs = {
            default = "",
            symlink = "",
            folder = {
              arrow_closed = "",
              arrow_open = "",
              default = "",
              open = "",
              empty = "",
              empty_open = "",
              symlink = "",
              symlink_open = "",
            },
            git = {
              unstaged = "✗",
              staged = "✓",
              unmerged = "",
              renamed = "➜",
              untracked = "★",
              deleted = "",
              ignored = "◌",
            },
          },
        },
      },
      filters = {
        dotfiles = false,
        custom = { "^.git$", "^node_modules$" },
      },
      git = {
        enable = true,
        ignore = false,
        timeout = 500,
      },
      actions = {
        open_file = {
          quit_on_open = false,
          window_picker = {
            enable = true,
            chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890",
            exclude = {
              filetype = { "notify", "packer", "qf", "diff", "fugitive", "fugitiveblame" },
              buftype = { "nofile", "terminal", "help" },
            },
          },
        },
      },
      diagnostics = {
        enable = true,
        show_on_dirs = true,
        icons = {
          hint = "",
          info = "",
          warning = "",
          error = "",
        },
      },
      filesystem_watchers = {
        enable = true,
        debounce_delay = 50,
      },
    })

  end,
}
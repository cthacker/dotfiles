-- Telescope Configuration

local status_ok, telescope = pcall(require, "telescope")
if not status_ok then
  return
end

-- Load telescope extensions
local fzf_ok, _ = pcall(require, "telescope._extensions.fzf")
if fzf_ok then
  telescope.load_extension('fzf')
else
  vim.notify("Telescope FZF extension not found. Run ':PlugInstall' and then compile the extension with 'cd ~/.config/nvim/plugged/telescope-fzf-native.nvim && make'", vim.log.levels.WARN)
end

-- Configure telescope
telescope.setup {
  defaults = {
    prompt_prefix = " ",
    selection_caret = " ",
    path_display = { "smart" },
    file_ignore_patterns = {
      ".git/",
      "node_modules/",
      "%.jpg",
      "%.jpeg",
      "%.png",
      "%.pdf",
      "%.zip",
      "%.tar.gz"
    },
  },
  extensions = {
    fzf = {
      fuzzy = true,
      override_generic_sorter = true,
      override_file_sorter = true,
      case_mode = "smart_case",
    }
  },
  pickers = {
    find_files = {
      hidden = true
    },
    buffers = {
      show_all_buffers = true,
      sort_lastused = true,
      mappings = {
        i = {
          ["<c-d>"] = "delete_buffer",
        }
      }
    }
  }
}

-- Key mappings (define these in your init.vim or init.lua)
-- nnoremap <leader>ff <cmd>Telescope find_files<CR>
-- nnoremap <leader>fg <cmd>Telescope live_grep<CR>
-- nnoremap <leader>fb <cmd>Telescope buffers<CR>
-- nnoremap <leader>fh <cmd>Telescope help_tags<CR>

return telescope 
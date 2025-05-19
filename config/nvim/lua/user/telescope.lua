-- Telescope configuration
-- Advanced fuzzy finding

local status_ok, telescope = pcall(require, "telescope")
if not status_ok then
  return
end

-- Import telescope actions
local actions = require "telescope.actions"

-- Setup telescope with custom settings
telescope.setup {
  defaults = {
    prompt_prefix = " ",
    selection_caret = " ",
    path_display = { "truncate" },
    selection_strategy = "reset",
    sorting_strategy = "ascending",
    layout_strategy = "horizontal",
    layout_config = {
      horizontal = {
        prompt_position = "top",
        preview_width = 0.55,
        results_width = 0.8,
      },
      vertical = {
        mirror = false,
      },
      width = 0.87,
      height = 0.80,
      preview_cutoff = 120,
    },
    
    mappings = {
      i = {
        ["<C-n>"] = actions.cycle_history_next,
        ["<C-p>"] = actions.cycle_history_prev,
        ["<C-j>"] = actions.move_selection_next,
        ["<C-k>"] = actions.move_selection_previous,
        ["<C-c>"] = actions.close,
        ["<Down>"] = actions.move_selection_next,
        ["<Up>"] = actions.move_selection_previous,
        ["<CR>"] = actions.select_default,
        ["<C-x>"] = actions.select_horizontal,
        ["<C-v>"] = actions.select_vertical,
        ["<C-t>"] = actions.select_tab,
        ["<C-u>"] = actions.preview_scrolling_up,
        ["<C-d>"] = actions.preview_scrolling_down,
        ["<PageUp>"] = actions.results_scrolling_up,
        ["<PageDown>"] = actions.results_scrolling_down,
        ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
        ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
        ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
        ["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
        ["<C-l>"] = actions.complete_tag,
        ["<C-_>"] = actions.which_key, -- keys from pressing <C-/>
        ["<c-d>"] = "delete_buffer", -- Keep the original buffer delete mapping
      },
    },
    file_ignore_patterns = {
      ".git/", "node_modules/", "%.jpg", "%.jpeg", "%.png", "%.pdf", "%.zip", "%.tar.gz",
      "%.o", "%.a", "%.out", "%.class", "%.mkv", "%.mp4"
    },
    -- Other customizations
    vimgrep_arguments = {
      "rg",
      "--color=never",
      "--no-heading",
      "--with-filename",
      "--line-number",
      "--column",
      "--smart-case",
      "--hidden",
    },
  },
  pickers = {
    -- Customizations for specific pickers
    find_files = {
      hidden = true
    },
    buffers = {
      show_all_buffers = true,
      sort_lastused = true,
    },
  },
  extensions = {
    -- Extensions like fzf-native for better performance
    fzf = {
      fuzzy = true,
      override_generic_sorter = true,
      override_file_sorter = true,
      case_mode = "smart_case",
    }
  },
}

-- Load telescope extensions
local fzf_ok, _ = pcall(require, "telescope._extensions.fzf")
if fzf_ok then
  telescope.load_extension('fzf')
else
  vim.notify("Install telescope-fzf-native.nvim for better performance", vim.log.levels.INFO)
end

return telescope
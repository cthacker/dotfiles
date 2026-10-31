-- Keys are mapped in user/navigate.lua, which uses this plugin inside tmux
-- and the rex CLI inside Rex.
return {
  "christoomey/vim-tmux-navigator",
  event = "VeryLazy",
  init = function()
    vim.g.tmux_navigator_no_mappings = 1
  end,
  config = function()
    require("user.navigate").setup()
  end,
}

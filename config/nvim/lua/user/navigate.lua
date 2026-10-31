-- Ctrl+h/j/k/l moves between Neovim splits, and past the edge into the
-- surrounding multiplexer's panes:
--   inside tmux  -> vim-tmux-navigator handles it, as before
--   inside Rex   -> the rex CLI moves focus to the neighbouring Rex pane
--   neither      -> plain split movement only
-- Rex's own ctrl+h/j/k/l bindings pass these keys through while nvim is in front.

local M = {}

local directions = {
  h = { rex = "left", tmux = "TmuxNavigateLeft" },
  j = { rex = "down", tmux = "TmuxNavigateDown" },
  k = { rex = "up", tmux = "TmuxNavigateUp" },
  l = { rex = "right", tmux = "TmuxNavigateRight" },
}

local function in_rex()
  return vim.env.REX_SESSION ~= nil and vim.fn.executable("rex") == 1
end

local function rex_focus(direction)
  vim.system({
    "rex", "api", "call", "-s", vim.env.REX_SESSION,
    "session.focus_direction", vim.json.encode({ direction = direction }),
  })
end

function M.navigate(key)
  local dir = directions[key]
  if vim.env.TMUX then
    vim.cmd(dir.tmux)
    return
  end
  local win = vim.api.nvim_get_current_win()
  vim.cmd("wincmd " .. key)
  if vim.api.nvim_get_current_win() == win and in_rex() then
    rex_focus(dir.rex)
  end
end

function M.setup()
  for key, dir in pairs(directions) do
    local lhs = "<C-" .. key .. ">"
    local desc = "Go to the split or pane " .. dir.rex
    -- Also from a :terminal, without leaving terminal mode first
    vim.keymap.set({ "n", "t" }, lhs, function() M.navigate(key) end, { silent = true, desc = desc })
  end
end

return M

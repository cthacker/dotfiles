-- Rex config. Reload with `rex config reload`; list bindings with `rex keymap`.
-- Caps Lock is remapped to Control in macOS, so every ctrl+... binding here is Caps Lock+...
-- Docs: https://www.superlogical.com/rex/docs/customize/keyboard-shortcuts

rex.bind("ctrl+cmd+k", "client.tab.previous")
rex.bind("ctrl+cmd+j", "client.tab.next")
rex.bind("cmd+shift+k", "client.tab.move.backward")
rex.bind("cmd+shift+j", "client.tab.move.forward")

-- Panes: ctrl+h/j/k/l, passed through to vim and fzf like the tmux is_vim check
local terminal = "com.superlogical.terminal"
local passthrough = {
  vi = true, vim = true, nvim = true, view = true, vimx = true, gvim = true,
  vimdiff = true, nvimdiff = true, fzf = true,
}

local function wants_keys(ctx)
  local proc = rex.block.call(terminal, "process", { block_id = ctx.block_id })
  local name = proc and proc.foreground and proc.foreground.name
  return name ~= nil and passthrough[name:lower()] == true
end

local function focus(direction)
  return function(ctx)
    if wants_keys(ctx) then
      return false
    end
    rex.session.focus_direction{ session_id = ctx.session_id, direction = direction }
    return true
  end
end

rex.bind("ctrl+h", focus("left"))
rex.bind("ctrl+j", focus("down"))
rex.bind("ctrl+k", focus("up"))
rex.bind("ctrl+l", focus("right"))

-- Resize the focused pane: ctrl+opt+h/j/k/l, add shift for bigger steps
for key, dir in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
  rex.bind("ctrl+alt+" .. key, "pane.resize", { direction = dir })
  rex.bind("ctrl+alt+shift+" .. key, "pane.resize", { direction = dir, amount = 15 })
end
rex.bind("ctrl+alt+=", "pane.balance")

-- Zoom and split panes: ctrl+cmd+enter zooms, ctrl+cmd+arrows split in that direction
rex.bind("ctrl+cmd+enter", "pane.zoom")
rex.bind("ctrl+cmd+left", "pane.split.left")
rex.bind("ctrl+cmd+right", "pane.split.right")
rex.bind("ctrl+cmd+up", "pane.split.up")
rex.bind("ctrl+cmd+down", "pane.split.down")

-- Open a file from the screen: ctrl+cmd+o (Caps Lock+Cmd+O) lists the file paths shown in
-- the focused pane; the one you pick opens beside it (see opener/pick.mjs). Works for
-- scripts, which Rex won't Cmd-click open.
rex.action{
  name = "open_file_from_pane",
  title = "Open File from Pane…",
  run = function(ctx)
    local _, err = rex.session.new_layer{
      bounds = { 0.1, 0.15, 0.8, 0.7 },
      focus = true,
      layout = rex.layout.block{
        flavor = terminal .. ".shell",
        options = { command = {
          os.getenv("HOME") .. "/checkouts/dotfiles/config/rex/opener/pick",
          ctx.session_id, ctx.block_id,
        } },
      },
    }
    if err ~= nil then error(err, 0) end
  end,
}
rex.bind("ctrl+cmd+o", "open_file_from_pane")

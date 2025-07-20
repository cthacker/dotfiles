-- Neovim Lua Configuration

-- Import all modules
local modules = {
  "user.telescope"
}

-- Load each module
for _, module in ipairs(modules) do
  local ok, err = pcall(require, module)
  if not ok then
    vim.notify("Error loading " .. module .. "\n\n" .. err, vim.log.levels.ERROR)
  end
end

-- Global options
vim.g.mapleader = " "  -- Set leader key to space
vim.opt.termguicolors = true

-- UI options
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.showmode = true
vim.opt.showcmd = true
vim.opt.signcolumn = "yes"
vim.opt.colorcolumn = "100"
vim.opt.scrolloff = 10
vim.opt.sidescrolloff = 8

-- Editing options
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.autoindent = true
vim.opt.smartindent = true

-- Search options
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- System options
vim.opt.backup = false
vim.opt.swapfile = false
vim.opt.undofile = true


-- Performance
vim.opt.updatetime = 300

-- Set colorscheme (if tokyonight is available)
local colorscheme_ok, _ = pcall(vim.cmd, "colorscheme tokyonight-moon")
if not colorscheme_ok then
  vim.notify("Failed to load colorscheme, falling back to default", vim.log.levels.WARN)
end 
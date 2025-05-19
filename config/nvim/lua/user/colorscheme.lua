-- Colorscheme configuration
-- Using Atom One Dark theme

-- Try to load the colorscheme
local status_ok, onedark = pcall(require, "onedark")
if not status_ok then
  -- Fallback to built-in theme if onedark is not available
  vim.cmd([[colorscheme habamax]])
  return
end

-- Configure onedark with custom settings
onedark.setup({
  style = "dark", -- Choose style: dark, darker, cool, deep, warm, warmer
  
  -- Custom colors to override default colors
  colors = {
    -- You can customize colors here if needed
  },
  
  -- Customize highlight groups
  highlights = {
    -- Custom highlight group overrides go here
  },
  
  -- Plugin integrations (set to false to disable)
  diagnostics = {
    darker = true, -- darker colors for diagnostic
    undercurl = true, -- use undercurl for diagnostics
    background = true, -- use background color for virtual text
  },
})

-- Enable the colorscheme
onedark.load()

-- Additional highlight customizations
vim.cmd([[
  " Additional highlight customizations that can't be done through the plugin's API
  highlight Comment gui=italic
  highlight LineNr guifg=#777777
]])
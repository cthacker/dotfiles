return {
  "navarasu/onedark.nvim",
  priority = 1000,
  config = function()
    local onedark = require("onedark")
    
    onedark.setup({
      style = "dark",
      colors = {},
      highlights = {},
      diagnostics = {
        darker = true,
        undercurl = true,
        background = true,
      },
    })

    onedark.load()

    vim.cmd([[
      highlight Comment gui=italic
      highlight LineNr guifg=#777777
    ]])
  end,
}
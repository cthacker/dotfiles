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
      highlight Comment guifg=#848b98 gui=italic
      highlight @comment guifg=#848b98 gui=italic
      highlight LineNr guifg=#777777
      " Matching bracket: a touch more visible than the default, still subtle.
      highlight MatchParen guibg=#4b5263 gui=bold
    ]])
  end,
}
return {
  "lukas-reineke/indent-blankline.nvim",
  main = "ibl",
  event = "BufReadPost",
  opts = {
    -- Turn off the "scope" highlight (vertical line + underline on the
    -- first/last line of the current block) that drew the purple box.
    scope = { enabled = false },
  },
}
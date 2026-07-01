-- Treesitter: structural parsing for highlighting, indent, incremental
-- selection, and textobjects (]m, af, if, ...).
--
-- This uses the `main` (rewrite) branch of nvim-treesitter + textobjects.
-- The old `master` branch is frozen upstream and broken on Neovim 0.12+
-- (its query layer predates the 0.11 iter_matches API change).
-- The main branch has no `configs.setup()` module system: highlighting and
-- indent are enabled per buffer, and all keymaps are defined explicitly.
-- Parser compilation requires the tree-sitter CLI (brew install tree-sitter-cli).
return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false, -- main branch does not support lazy-loading
    build = ":TSUpdate",
    config = function()
      local ts = require("nvim-treesitter")

      -- Parsers to install up front (async; no-op once installed).
      ts.install({
        "c", "lua", "vim", "vimdoc", "query",
        "bash", "javascript", "typescript", "python",
        "html", "css", "markdown", "markdown_inline",
        "json", "yaml", "toml", "rust", "go",
      })

      -- ---- <CR>/<BS> incremental selection --------------------------------
      -- The main branch dropped this feature, so it lives here: <CR> selects
      -- the node under the cursor, <CR> again expands to the parent node,
      -- <BS> shrinks back. (The old <S-CR> scope_incremental is gone.)
      local sel_stacks = {} -- bufnr -> stack of selected nodes

      local function select_node(node)
        local sr, sc, er, ec = node:range()
        if ec == 0 then -- exclusive end at col 0 means "end of previous line"
          er = er - 1
          ec = #(vim.api.nvim_buf_get_lines(0, er, er + 1, false)[1] or "")
        end
        if vim.api.nvim_get_mode().mode:match("^[vV\22]") then
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
        end
        vim.fn.setpos("'<", { 0, sr + 1, sc + 1, 0 })
        vim.fn.setpos("'>", { 0, er + 1, math.max(ec, 1), 0 })
        vim.cmd("normal! gv")
      end

      local function init_selection()
        local node = vim.treesitter.get_node()
        if not node then return end
        sel_stacks[vim.api.nvim_get_current_buf()] = { node }
        select_node(node)
      end

      local function expand_selection()
        local stack = sel_stacks[vim.api.nvim_get_current_buf()]
        if not stack or #stack == 0 then return init_selection() end
        local cur = stack[#stack]
        local parent = cur:parent()
        -- skip ancestors that cover the exact same text
        while parent and vim.deep_equal({ parent:range() }, { cur:range() }) do
          cur, parent = parent, parent:parent()
        end
        if parent then table.insert(stack, parent) end
        select_node(stack[#stack])
      end

      local function shrink_selection()
        local stack = sel_stacks[vim.api.nvim_get_current_buf()]
        if not stack or #stack == 0 then return end
        if #stack > 1 then table.remove(stack) end
        select_node(stack[#stack])
      end

      -- ---- textobject keymaps ---------------------------------------------
      -- Defined per buffer (below) rather than globally: buffer-local maps
      -- take precedence over the motions Neovim's stock ftplugins define
      -- (python.vim maps ]]/][/[m/]m/... buffer-locally and would otherwise
      -- shadow these). The require() calls resolve at keypress time.
      local select_maps = {
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["ac"] = "@class.outer",
        ["ic"] = "@class.inner",
        ["aa"] = "@parameter.outer",
        ["ia"] = "@parameter.inner",
        ["ab"] = "@block.outer",
        ["ib"] = "@block.inner",
        ["al"] = "@loop.outer",
        ["il"] = "@loop.inner",
        ["ai"] = "@conditional.outer",
        ["ii"] = "@conditional.inner",
        ["as"] = "@statement.outer",
        ["is"] = "@statement.inner", -- note: python only defines @statement.outer
        ["am"] = "@comment.outer",
        ["im"] = "@comment.inner",
      }
      local move_maps = {
        { "]m", "goto_next_start", "@function.outer" },
        { "]]", "goto_next_start", "@class.outer" },
        { "]M", "goto_next_end", "@function.outer" },
        { "][", "goto_next_end", "@class.outer" },
        { "[m", "goto_previous_start", "@function.outer" },
        { "[[", "goto_previous_start", "@class.outer" },
        { "[M", "goto_previous_end", "@function.outer" },
        { "[]", "goto_previous_end", "@class.outer" },
      }

      local function set_buffer_keymaps(buf)
        vim.keymap.set("n", "<CR>", init_selection,
          { buffer = buf, desc = "TS: select node under cursor" })
        vim.keymap.set("x", "<CR>", expand_selection,
          { buffer = buf, desc = "TS: expand selection to parent node" })
        vim.keymap.set("x", "<BS>", shrink_selection,
          { buffer = buf, desc = "TS: shrink selection" })
        for lhs, capture in pairs(select_maps) do
          vim.keymap.set({ "x", "o" }, lhs, function()
            require("nvim-treesitter-textobjects.select").select_textobject(capture, "textobjects")
          end, { buffer = buf, desc = "TS select " .. capture })
        end
        for _, m in ipairs(move_maps) do
          vim.keymap.set({ "n", "x", "o" }, m[1], function()
            require("nvim-treesitter-textobjects.move")[m[2]](m[3], "textobjects")
          end, { buffer = buf, desc = "TS " .. m[2] .. " " .. m[3] })
        end
      end

      -- ---- per-buffer enable ----------------------------------------------
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("user_treesitter", { clear = true }),
        callback = function(args)
          local buf = args.buf
          local lang = vim.treesitter.language.get_lang(args.match)
          if not lang then return end

          -- regex highlighting is fine for huge files; parsing them is not
          local max_filesize = 100 * 1024
          local ok_stat, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
          if ok_stat and stats and stats.size > max_filesize then return end

          if not pcall(vim.treesitter.start, buf, lang) then
            -- no parser yet: fetch it in the background (auto_install parity);
            -- buffers opened after it lands get highlighting
            if vim.tbl_contains(ts.get_available(), lang) then ts.install(lang) end
            return
          end

          if args.match ~= "yaml" then
            vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end

          -- scheduled so these land after ftplugin maps and win precedence
          vim.schedule(function()
            if vim.api.nvim_buf_is_valid(buf) then set_buffer_keymaps(buf) end
          end)
        end,
      })
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    lazy = false,
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("nvim-treesitter-textobjects").setup({
        select = { lookahead = true },
        move = { set_jumps = true },
      })
    end,
  },
}

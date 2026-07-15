-- Python (and general) LSP:
--   Ruff    -> linting, auto-fix, formatting (your modern flake8 + isort + black)
--   basedpyright -> autocomplete, hover (with stdlib docstrings), and go-to-definition
-- Servers install automatically via mason on first launch (run :Mason to check).
return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    { "mason-org/mason.nvim", opts = {} }, -- installer; lazy runs mason.setup()
    "mason-org/mason-lspconfig.nvim",
  },
  config = function()
    -- Install the servers if missing; we enable them ourselves below.
    require("mason-lspconfig").setup({
      ensure_installed = { "basedpyright", "ruff" },
      automatic_enable = false,
    })

    -- Ruff owns lint + format; let basedpyright be the single source of hover docs
    -- so you don't get two popups for the same symbol. Only report likely bugs:
    -- syntax/runtime failures and undefined names, not style or unused-code noise.
    vim.lsp.config("ruff", {
      init_options = {
        settings = {
          lint = { select = { "E9", "F63", "F7", "F82" } },
        },
      },
      on_attach = function(client)
        client.server_capabilities.hoverProvider = false
      end,
    })

    -- Keep basedpyright for completion, hover, and navigation, but leave type
    -- checking off. Ruff above remains responsible for actionable diagnostics.
    vim.lsp.config("basedpyright", {
      settings = {
        basedpyright = {
          analysis = {
            diagnosticMode = "openFilesOnly",
            typeCheckingMode = "off",
          },
        },
      },
    })

    -- Start the servers (their base configs ship with nvim-lspconfig).
    vim.lsp.enable({ "basedpyright", "ruff" })

    -- Only render actual errors. Warnings, hints, and informational diagnostics
    -- stay available to tools without filling the editor with visual noise.
    local errors_only = { severity = vim.diagnostic.severity.ERROR }
    vim.diagnostic.config({
      virtual_text = errors_only,
      signs = errors_only,
      underline = errors_only,
      severity_sort = true,
      update_in_insert = false,
    })

    -- Per-buffer setup whenever a language server attaches to a file.
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("user_lsp_attach", { clear = true }),
      callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        local buf = args.buf

        -- The only new keymap. The rest (K, gr*, gO, [d, ]d) are nvim defaults.
        vim.keymap.set("n", "gd", vim.lsp.buf.definition,
          { buffer = buf, silent = true, desc = "LSP: go to definition" })

        -- As-you-type completion (built into Neovim 0.12; no nvim-cmp needed).
        if client and client:supports_method("textDocument/completion") then
          vim.lsp.completion.enable(true, client.id, buf, { autotrigger = true })
        end

        -- Python diagnostics start hidden and are revealed after a save.
        if vim.bo[buf].filetype == "python"
            and vim.b[buf].python_diagnostics_saved ~= true then
          vim.diagnostic.enable(false, { bufnr = buf })
        end
      end,
    })

    local diagnostics_group = vim.api.nvim_create_augroup(
      "user_python_diagnostics_on_save", { clear = true })

    -- Hide stale diagnostics as soon as the saved file is edited again.
    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "TextChangedP" }, {
      group = diagnostics_group,
      pattern = "*.py",
      callback = function(args)
        if vim.bo[args.buf].modified then
          vim.b[args.buf].python_diagnostics_saved = false
          vim.diagnostic.enable(false, { bufnr = args.buf })
        end
      end,
    })

    -- Show the latest error-only diagnostics after a successful save.
    vim.api.nvim_create_autocmd("BufWritePost", {
      group = diagnostics_group,
      pattern = "*.py",
      callback = function(args)
        vim.b[args.buf].python_diagnostics_saved = true
        vim.diagnostic.enable(true, { bufnr = args.buf })
      end,
    })

    -- Ruff: format + organize imports on save. Wrapped in pcall so a hiccup
    -- can never block your :w.
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = vim.api.nvim_create_augroup("user_ruff_format", { clear = true }),
      pattern = "*.py",
      callback = function(args)
        pcall(function()
          -- 1) sort/organize imports via Ruff (synchronous, no popup)
          for _, client in ipairs(vim.lsp.get_clients({ bufnr = args.buf, name = "ruff" })) do
            local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
            params.context = { only = { "source.organizeImports.ruff" }, diagnostics = {} }
            local res = client:request_sync("textDocument/codeAction", params, 1000, args.buf)
            for _, action in ipairs((res or {}).result or {}) do
              -- Ruff returns a stub action; resolve it to get the real edit.
              if not action.edit and action.data then
                local resolved = client:request_sync("codeAction/resolve", action, 1000, args.buf)
                action = (resolved or {}).result or action
              end
              if action.edit then
                vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
              end
            end
          end
          -- 2) format the buffer with Ruff
          vim.lsp.buf.format({
            async = false,
            filter = function(c) return c.name == "ruff" end,
          })
        end)
      end,
    })
  end,
}

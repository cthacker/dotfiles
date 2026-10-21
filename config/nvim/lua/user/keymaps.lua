-- Keymaps for Neovim
-- Using the newer vim.keymap.set API

local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }

keymap("", "<Space>", "<Nop>", opts)

-- Normal mode mappings --
-- Window navigation, <leader>/, ii, and <leader>y/d/x/p/P live in vimrc.

-- Nvim-tree file explorer
keymap("n", "<leader>nn", ":NvimTreeToggle<CR>", opts)
keymap("n", "<leader>nf", ":NvimTreeFindFile<CR>", opts)

-- Telescope
keymap("n", "<leader>ff", "<cmd>Telescope find_files<CR>", opts)
keymap("n", "<leader>fg", "<cmd>Telescope live_grep<CR>", opts)
keymap("n", "<leader>fb", "<cmd>Telescope buffers<CR>", opts)
keymap("n", "<leader>fh", "<cmd>Telescope help_tags<CR>", opts)
keymap("n", "<leader>fc", "<cmd>Telescope colorscheme<CR>", opts)
keymap("n", "<leader>fr", "<cmd>Telescope oldfiles<CR>", opts)
keymap("n", "<c-p>", "<cmd>Telescope find_files<CR>", opts)

-- Buffer navigation
keymap("n", "<S-l>", ":bnext<CR>", opts)
keymap("n", "<S-h>", ":bprevious<CR>", opts)
keymap("n", "<leader>bc", ":bdelete<CR>", opts)

-- Move text up and down
keymap("n", "<A-j>", ":m .+1<CR>==", opts)
keymap("n", "<A-k>", ":m .-2<CR>==", opts)

-- Insert mode mappings --
-- macOS-style motion without leaving insert mode
-- Option+h/l = move by word (needs `macos-option-as-alt` in ghostty config)
keymap("i", "<A-h>", "<C-o>b", opts)  -- word left
keymap("i", "<A-l>", "<C-o>w", opts)  -- word right
-- Command+h/l = start/end of line: ghostty sends Home/End for cmd+h/cmd+l,
-- which insert mode handles natively, so no <D-...> mapping is needed here.

-- Visual mode mappings --
-- Stay in indent mode when changing indentation
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)

-- Move text up and down
keymap("v", "<A-j>", ":m '>+1<CR>gv=gv", opts)
keymap("v", "<A-k>", ":m '<-2<CR>gv=gv", opts)

-- Don't overwrite register when pasting over selection
keymap("v", "p", '"_dP', opts)

-- Clipboard: Y variants (y/p/P are in vimrc)
keymap({ "n", "v" }, "<leader>Y", '"+Y', opts)

-- Markdown preview
keymap("n", "<leader>mp", ":MarkdownPreviewToggle<CR>", opts)

-- Terminal mode mappings --
-- Better terminal navigation
keymap("t", "<C-h>", "<C-\\><C-N><C-w>h", opts)
keymap("t", "<C-j>", "<C-\\><C-N><C-w>j", opts)
keymap("t", "<C-k>", "<C-\\><C-N><C-w>k", opts)
keymap("t", "<C-l>", "<C-\\><C-N><C-w>l", opts)
keymap("t", "<Esc>", "<C-\\><C-n>", opts)

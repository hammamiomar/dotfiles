-- Neovim config — single file, quiet by default.
-- Diagnostics live in the gutter (<Space>d expands), plugins are the minimum
-- for LSP navigation, fuzzy finding, treesitter, and markdown reading.

-- ---------------------------------------------------------------------------
-- Options
-- ---------------------------------------------------------------------------
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- netrw off; yazi.nvim handles directories
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

local opt = vim.opt

opt.autowrite = true
opt.clipboard = "unnamedplus"
opt.confirm = true
opt.cursorline = true
opt.expandtab = true
opt.ignorecase = true
opt.smartcase = true
opt.linebreak = true
opt.mouse = "a"
opt.number = true
opt.scrolloff = 6
opt.shiftwidth = 2
opt.tabstop = 2
opt.smartindent = true
opt.splitbelow = true
opt.splitright = true
opt.wrap = false
opt.showmode = true
opt.shortmess:append({ c = true, C = true, I = true })
opt.undofile = true
opt.updatetime = 300
opt.signcolumn = "yes"
opt.winborder = "rounded"

-- Reload files edited outside nvim (agents, formatters, other panes)
opt.autoread = true

-- Treesitter folds; zM folds a file to its outline, zR reopens
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldtext = ""

-- ---------------------------------------------------------------------------
-- Autocommands
-- ---------------------------------------------------------------------------
local aug = vim.api.nvim_create_augroup("omar", { clear = true })

vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
  group = aug,
  callback = function()
    if vim.o.buftype == "" then vim.cmd("checktime") end
  end,
})

vim.api.nvim_create_autocmd("FileChangedShellPost", {
  group = aug,
  callback = function(ev)
    vim.notify("Reloaded from disk: " .. vim.fn.fnamemodify(ev.file, ":t"))
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = aug,
  pattern = { "markdown", "text", "gitcommit" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
  end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
  group = aug,
  callback = function() vim.hl.on_yank() end,
})

-- ---------------------------------------------------------------------------
-- Keymaps (plugin keymaps live with their plugin specs)
-- ---------------------------------------------------------------------------
local map = vim.keymap.set

map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })
map("n", "<leader>w", "<cmd>write<cr>", { desc = "Save file" })
map("n", "<leader>q", "<cmd>quit<cr>", { desc = "Close window" })
map("n", "<leader>d", vim.diagnostic.open_float, { desc = "Diagnostic under cursor" })

map("n", "<C-d>", "<C-d>zz", { desc = "Half page down (centered)" })
map("n", "<C-u>", "<C-u>zz", { desc = "Half page up (centered)" })
map("n", "n", "nzzzv", { desc = "Next match (centered)" })
map("n", "N", "Nzzzv", { desc = "Previous match (centered)" })

map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Leave terminal mode" })

-- ---------------------------------------------------------------------------
-- Plugins (lazy.nvim)
-- ---------------------------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath,
  })
end
opt.rtp:prepend(lazypath)

require("lazy").setup({

  -- Colorschemes: kanagawa-dragon (dark) / melange (light), see theme section
  { "rebelot/kanagawa.nvim", lazy = false, priority = 1000 },
  { "savq/melange-nvim", lazy = false, priority = 1000 },

  -- Treesitter: highlighting, folds, outline
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    lazy = false,
    config = function()
      require("nvim-treesitter").install({
        "bash", "css", "diff", "fish", "go", "gomod", "html", "javascript",
        "json", "lua", "markdown", "markdown_inline", "python",
        "regex", "rust", "toml", "tsx", "typescript", "vim", "vimdoc", "yaml",
      })
      vim.api.nvim_create_autocmd("FileType", {
        group = aug,
        callback = function(ev) pcall(vim.treesitter.start, ev.buf) end,
      })
    end,
  },

  -- LSP servers, installed and enabled via mason
  { "neovim/nvim-lspconfig" },
  { "mason-org/mason.nvim", opts = {} },
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = { "mason-org/mason.nvim", "neovim/nvim-lspconfig" },
    opts = {
      ensure_installed = { "lua_ls", "pyright", "ts_ls" },
    },
  },

  -- Neovim API types for lua_ls when editing this config
  { "folke/lazydev.nvim", ft = "lua", opts = {} },

  -- Completion
  {
    "saghen/blink.cmp",
    version = "1.*", -- release pin required for the prebuilt fuzzy matcher
    event = "InsertEnter",
    opts = {
      keymap = { preset = "super-tab" },
      completion = { documentation = { auto_show = true, auto_show_delay_ms = 300 } },
      sources = {
        default = { "lazydev", "lsp", "path", "buffer" },
        providers = {
          lazydev = { name = "LazyDev", module = "lazydev.integrations.blink", score_offset = 100 },
        },
      },
      fuzzy = { implementation = "prefer_rust_with_warning" },
    },
  },

  -- Fuzzy finding: files, grep, symbols. <C-v>/<C-x> open in splits.
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    config = function()
      require("telescope").setup({
        defaults = {
          path_display = { "filename_first" },
        },
      })
      pcall(require("telescope").load_extension, "fzf")

      local tb = require("telescope.builtin")
      map("n", "<leader>f", function() tb.find_files({ hidden = true }) end, { desc = "Find file" })
      map("n", "<leader>g", tb.live_grep, { desc = "Grep project" })
      map("n", "<leader>b", function() tb.buffers({ sort_mru = true, ignore_current_buffer = true }) end,
        { desc = "Buffers (recent first)" })
      map("n", "<leader>*", tb.grep_string, { desc = "Grep word under cursor" })
      map("n", "<leader>r", tb.resume, { desc = "Resume last picker" })
      map("n", "<leader>?", tb.keymaps, { desc = "Search keymaps" })
    end,
  },

  -- Label-based jumps: s = anywhere, S = word starts
  {
    "folke/flash.nvim",
    opts = {
      modes = { search = { enabled = false }, char = { enabled = false } },
    },
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash jump" },
      {
        "S", mode = { "n", "x", "o" },
        function()
          require("flash").jump({
            search = { mode = function(str) return "\\<" .. vim.pesc(str) end },
          })
        end,
        desc = "Flash jump (word starts)",
      },
    },
  },

  -- Git hunk signs and navigation
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      on_attach = function(bufnr)
        local gs = require("gitsigns")
        local function bmap(mode, l, r, desc)
          vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
        end
        bmap("n", "]h", function() gs.nav_hunk("next") end, "Next hunk")
        bmap("n", "[h", function() gs.nav_hunk("prev") end, "Previous hunk")
        bmap("n", "<leader>hp", gs.preview_hunk, "Preview hunk")
        bmap("n", "<leader>hb", function() gs.blame_line({ full = true }) end, "Blame line")
        bmap("n", "<leader>hs", gs.stage_hunk, "Stage hunk")
        bmap("n", "<leader>hr", gs.reset_hunk, "Reset hunk")
      end,
    },
  },

  -- In-buffer markdown rendering
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = "markdown",
    dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.icons" },
    opts = {
      latex = { enabled = false }, -- snacks.image typesets latex instead
    },
  },

  -- Inline images and typeset LaTeX math in markdown (kitty graphics
  -- protocol; requires imagemagick + a latex install for math)
  {
    "folke/snacks.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      image = { enabled = true },
    },
  },

  {
    "echasnovski/mini.icons",
    config = function()
      require("mini.icons").setup()
      MiniIcons.mock_nvim_web_devicons()
    end,
  },

  -- File manager (floating yazi); also handles `nvim <dir>`
  {
    "mikavilpas/yazi.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    lazy = false, -- required for open_for_directories
    keys = {
      { "<leader>y", "<cmd>Yazi<cr>", desc = "Yazi at current file" },
      { "<leader>Y", "<cmd>Yazi cwd<cr>", desc = "Yazi at cwd" },
    },
    opts = { open_for_directories = true },
  },

  -- Symbol outline sidebar
  {
    "stevearc/aerial.nvim",
    opts = { layout = { default_direction = "prefer_right", min_width = 28 } },
    keys = { { "<leader>o", "<cmd>AerialToggle!<cr>", desc = "Symbol outline" } },
  },

  -- Keybinding hints
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "helix",
      delay = 0,
      spec = {
        { "<leader>h", group = "git hunks" },
      },
    },
  },

  -- <C-h/j/k/l> across nvim splits and tmux panes
  { "christoomey/vim-tmux-navigator" },

  -- Per-file indentation detection
  { "tpope/vim-sleuth" },

}, {
  ui = { border = "rounded" },
  change_detection = { notify = false },
})

-- ---------------------------------------------------------------------------
-- Theme: follows macOS appearance (kanagawa-dragon dark / melange light)
-- ---------------------------------------------------------------------------
local current_mode = nil

local function set_theme(dark)
  local mode = dark and "dark" or "light"
  if mode == current_mode then return end
  current_mode = mode
  if dark then
    vim.o.background = "dark"
    require("kanagawa").setup({
      theme = "dragon",
      colors = {
        palette = {
          dragonBlue = "#957FB8",
          dragonBlue2 = "#938AA9",
          waveBlue1 = "#2D2A3E",
          waveBlue2 = "#3D3A50",
          dragonGreen = "#76946A",
          dragonGreen2 = "#98BB6C",
        },
        theme = { dragon = { ui = { bg_visual = "#3D3A50", bg_search = "#4D4A60" } } },
      },
    })
    vim.cmd.colorscheme("kanagawa-dragon")
    vim.api.nvim_set_hl(0, "ModeMsg", { fg = "#98BB6C", bold = true })
  else
    vim.o.background = "light"
    vim.cmd.colorscheme("melange")
  end
end

local dark_cmd = { "defaults", "read", "-g", "AppleInterfaceStyle" }

-- Synchronous check once at startup; async (non-blocking) on focus changes
local startup = vim.system(dark_cmd, { text = true }):wait()
set_theme(startup.code == 0 and startup.stdout:match("Dark") ~= nil)

local function apply_system_theme()
  vim.system(dark_cmd, { text = true }, function(result)
    local dark = result.code == 0 and result.stdout and result.stdout:match("Dark") ~= nil
    vim.schedule(function() set_theme(dark) end)
  end)
end

vim.api.nvim_create_autocmd({ "FocusGained", "VimResume" }, {
  group = aug,
  callback = apply_system_theme,
})
map("n", "<leader>ut", function()
  current_mode = nil
  apply_system_theme()
end, { desc = "Refresh theme" })

-- ---------------------------------------------------------------------------
-- Diagnostics: gutter signs only; <Space>d shows details, ]d / [d navigate
-- ---------------------------------------------------------------------------
vim.diagnostic.config({
  virtual_text = false,
  underline = false,
  signs = true,
  update_in_insert = false,
  severity_sort = true,
  float = { source = true },
})

-- ---------------------------------------------------------------------------
-- LSP
-- ---------------------------------------------------------------------------
-- rust-analyzer comes from rustup (not mason) so it tracks `rustup update`
vim.lsp.enable("rust_analyzer")

vim.lsp.config("pyright", {
  settings = {
    python = {
      analysis = { typeCheckingMode = "basic", diagnosticMode = "openFilesOnly" },
    },
  },
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = aug,
  callback = function(ev)
    local tb = require("telescope.builtin")
    local function bmap(keys, fn, desc)
      vim.keymap.set("n", keys, fn, { buffer = ev.buf, desc = desc })
    end
    bmap("gd", tb.lsp_definitions, "Go to definition")
    bmap("gr", tb.lsp_references, "References")
    bmap("gI", tb.lsp_implementations, "Implementations")
    bmap("gy", tb.lsp_type_definitions, "Type definition")
    bmap("<leader>s", tb.lsp_document_symbols, "Document symbols")
    bmap("<leader>S", tb.lsp_dynamic_workspace_symbols, "Workspace symbols")
    -- Built in: K hover, grn rename, gra code action, <C-o>/<C-i> jumplist
  end,
})

-- OPTIONS
vim.g.have_nerd_font = true

vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

local tab_width = 4
vim.opt.expandtab = true
vim.opt.tabstop = tab_width
vim.opt.softtabstop = tab_width
vim.opt.shiftwidth = tab_width

vim.opt.cursorline = true
vim.opt.scrolloff = 6
vim.opt.confirm = true

vim.opt.splitright = true
vim.opt.splitbelow = true

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.mouse = "a"
vim.opt.showmode = false

vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.autoread = true

vim.diagnostic.config({
    update_in_insert = false,
    severity_sort = true,
    float = { border = "rounded", source = "if_many" },
    underline = { severity = { min = vim.diagnostic.severity.WARN } },
    virtual_text = true,
    virtual_lines = false,
    jump = { float = true },
})

-- KEYMAPS
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

vim.keymap.set("x", "<leader>p", [["_dP]])
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])
vim.keymap.set({ "n", "v" }, "<leader>d", '"_d')

vim.keymap.set("n", "Q", "<nop>")

vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
vim.keymap.set("n", "<leader>ss", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

vim.keymap.set("n", "<leader><leader>x", "<cmd>:Explore<CR>")

-- AUTOCOMMANDS
vim.api.nvim_create_autocmd("TextYankPost", {
    desc = "Highlight when yanking (copying) text",
    group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
    callback = function()
        vim.hl.on_yank()
    end,
})

vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "CursorHoldI", "FocusGained" }, {
    command = "if mode() != 'c' | checktime | endif",
    pattern = { "*" },
})

-- PACKAGES
-- General dependencies
vim.pack.add({ "https://github.com/nvim-tree/nvim-web-devicons" })
vim.pack.add({ "https://github.com/nvim-lua/plenary.nvim" })
vim.pack.add({ "https://github.com/MeanderingProgrammer/render-markdown.nvim" })
require("render-markdown").setup({
    latex = { enabled = false },
})

-- Tokyo Night color scheme
vim.pack.add({ "https://github.com/folke/tokyonight.nvim" })
vim.cmd([[colorscheme tokyonight]])

-- Dired
vim.pack.add({ "https://github.com/stevearc/oil.nvim.git" })
require("oil").setup()
vim.keymap.set({ "n", "v" }, "<leader><leader>x", "<cmd>:Oil<CR>", { desc = "Open File e[x]plorer" })

-- Tree-sitter
vim.pack.add({ "https://github.com/nvim-treesitter/nvim-treesitter" })
require("nvim-treesitter").install({
    "lua",
    "vimdoc",
    "c",
    "rust",
    "python",
    "markdown",
    "json",
    "yaml",
    "typescript",
    "html",
    "bash",
    "css",
})

-- Which-key
vim.pack.add({ "https://github.com/folke/which-key.nvim" })
require("which-key").setup()

-- Colorizer
vim.pack.add({ "https://github.com/norcalli/nvim-colorizer.lua" })
require("colorizer").setup()

-- AutoPair
vim.pack.add({ "https://github.com/windwp/nvim-autopairs" })
require("nvim-autopairs").setup()

-- Fidget
vim.pack.add({ "https://github.com/j-hui/fidget.nvim.git" })
require("fidget").setup({})

-- Git Integration
vim.pack.add({ "https://github.com/lewis6991/gitsigns.nvim" })
local gitsigns = require("gitsigns")
gitsigns.setup()
vim.keymap.set("n", "<leader>hp", gitsigns.preview_hunk, { desc = "[P]review hunk" })
vim.keymap.set("n", "<leader>hr", gitsigns.reset_hunk, { desc = "[R]eset hunk" })
vim.keymap.set("n", "<leader>hs", gitsigns.stage_hunk, { desc = "[S]tage hunk" })
vim.keymap.set("n", "<leader>hd", gitsigns.diffthis, { desc = "[D]iff" })
vim.keymap.set("n", "<leader>htb", gitsigns.toggle_current_line_blame, { desc = "[T]oggle [b]lame" })
vim.keymap.set("n", "[h", function()
    gitsigns.nav_hunk("prev")
end, { desc = "Previous hunk" })
vim.keymap.set("n", "]h", function()
    gitsigns.nav_hunk("next")
end, { desc = "Next hunk" })

vim.pack.add({ "https://github.com/sindrets/diffview.nvim.git" })
vim.pack.add({ "https://github.com/m00qek/baleia.nvim.git" })
local baleia = require("baleia").setup({})
vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
    pattern = "*.log",
    callback = function()
        baleia.automatically(vim.api.nvim_get_current_buf())
    end,
})

vim.pack.add({ "https://github.com/NeogitOrg/neogit.git" })
local neogit = require("neogit")
neogit.setup({})
vim.keymap.set("n", "<leader>hc", neogit.open, { desc = "Open Neogit UI" })

-- Vim-Be-Good
vim.pack.add({ "https://github.com/ThePrimeagen/vim-be-good" })

-- Mini AI
vim.pack.add({ "https://github.com/nvim-mini/mini.nvim" })
require("mini.ai").setup()

-- Comment
vim.pack.add({ "https://github.com/numToStr/Comment.nvim" })
require("Comment").setup()

-- Todo Comments
vim.pack.add({ "https://github.com/folke/todo-comments.nvim" })
require("todo-comments").setup()

-- Lualine
vim.pack.add({ "https://github.com/nvim-lualine/lualine.nvim" })
require("lualine").setup({})

-- Telescope
vim.pack.add({ "https://github.com/nvim-telescope/telescope.nvim" })

local telescope_builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", telescope_builtin.find_files, { desc = "Find [f]iles" })
vim.keymap.set("n", "<leader>fg", telescope_builtin.live_grep, { desc = "Find live [g]rep" })
vim.keymap.set("n", "<leader>fb", telescope_builtin.buffers, { desc = "Find [b]uffers" })
vim.keymap.set("n", "<leader>fh", telescope_builtin.help_tags, { desc = "Find [h]elp tags" })
vim.keymap.set("n", "<leader>fd", telescope_builtin.diagnostics, { desc = "Find [d]iagnostics" })
vim.keymap.set("n", "<leader>fw", telescope_builtin.grep_string, { desc = "Find current [w]ord in buffer" })
vim.keymap.set("n", "<leader>fr", telescope_builtin.oldfiles, { desc = "Find [r]ecent files" })

-- AI Intregration
vim.pack.add({ "https://www.github.com/olimorris/codecompanion.nvim" })
---@diagnostic disable-next-line: undefined-field
require("codecompanion").setup({
    interactions = {
        chat = {
            adapter = "opencode",
        },
        inline = {
            adapter = "opencode",
        },
        cmd = {
            adapter = "opencode",
        },
        cli = {
            agent = "opencode",
            agents = {
                opencode = {
                    cmd = "opencode",
                    args = {},
                    description = "OpenCode",
                    provider = "terminal",
                },
            },
        },
    },
})

vim.keymap.set("n", "<leader>ca", "<cmd>:CodeCompanionActions<CR>", { desc = "Open [C]ode[C]ompanion Actions window" })

vim.keymap.set({ "n", "v" }, "<leader>cc", function()
    ---@diagnostic disable-next-line: undefined-field
    require("codecompanion").toggle()
end, { desc = "[C]ode[C]ompanion toggle" })

-- [C]odeCompanion [P]rompt]
vim.keymap.set({ "n", "v" }, "<LocalLeader>cp", function()
    ---@diagnostic disable-next-line: undefined-field
    return require("codecompanion").cli({ prompt = true })
end, { desc = "Prompt the CLI agent" })

-- [C]odeCompanion [I]nclude
vim.keymap.set({ "n", "v" }, "<LocalLeader>ci", function()
    ---@diagnostic disable-next-line: undefined-field
    return require("codecompanion").cli("#{this}", { focus = false })
end, { desc = "Add context to the CLI agent" })

-- [C]odeCompanion [D]iagnostics
vim.keymap.set("n", "<LocalLeader>cd", function()
    ---@diagnostic disable-next-line: undefined-field
    return require("codecompanion").cli("#{diagnostics} Can you fix these?", { focus = false, submit = true })
end, { desc = "Send diagnostics to CLI agent" })

-- [C]odeCompanion [T]erminal
vim.keymap.set("n", "<LocalLeader>ct", function()
    ---@diagnostic disable-next-line: undefined-field
    return require("codecompanion").cli(
        "#{terminal} Sharing the output from the terminal. Can you fix it?",
        { focus = false, submit = true }
    )
end, { desc = "Send terminal output to CLI agent" })

-- Completion and Snippets
vim.pack.add({ "https://github.com/rafamadriz/friendly-snippets" })
vim.pack.add({ "https://github.com/L3MON4D3/LuaSnip" })
vim.pack.add({ { src = "https://github.com/saghen/blink.cmp", version = "v1" } })

require("luasnip.loaders.from_vscode").lazy_load()
require("blink.cmp").setup({
    keymap = { preset = "default" },
    appearance = {
        nerd_font_variant = "mono",
    },
    completion = { documentation = { auto_show = false } },
    sources = {
        default = { "lsp", "path", "snippets", "buffer" },
    },
    fuzzy = { implementation = "lua" },
})

-- LSP and Formatting
vim.pack.add({ "https://github.com/neovim/nvim-lspconfig" })
vim.pack.add({ "https://github.com/mason-org/mason.nvim" })
vim.pack.add({ "https://github.com/mason-org/mason-lspconfig.nvim" })
vim.pack.add({ "https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim" })
vim.pack.add({ "https://github.com/stevearc/conform.nvim" })

require("mason").setup()
require("mason-lspconfig").setup()
require("mason-tool-installer").setup({
    ensure_installed = { "lua_ls", "stylua", "clangd", "pyright", "black", "isort", "rust-analyzer" },
})

vim.lsp.config("lua_ls", {
    settings = {
        Lua = {
            runtime = {
                version = "LuaJIT",
            },
            diagnostics = {
                globals = {
                    "vim",
                    "require",
                },
            },
            workspace = {
                library = vim.api.nvim_get_runtime_file("", true),
            },
            telemetry = {
                enable = false,
            },
        },
    },
})

local conform = require("conform")
conform.setup({
    formatters_by_ft = {
        lua = { "stylua" },
        python = { "isort", "black" },
        rust = { "rustfmt", lsp_format = "fallback" },
    },
    format_on_save = {
        timeout_ms = 500,
        lsp_format = "fallback",
    },
})

vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
vim.keymap.set("n", "gra", vim.lsp.buf.code_action, { desc = "[A]ct on code" })
vim.keymap.set("n", "grD", vim.lsp.buf.declaration, { desc = "Jump to [D]eclaration/header for the symbol" })
vim.keymap.set("n", "grn", vim.lsp.buf.rename, { desc = "Re[n]name symbol" })
vim.keymap.set("n", "grf", conform.format, { desc = "[F]ormat buffer" })

vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("telescope-lsp-attach", { clear = true }),
    callback = function(event)
        local buf = event.buf
        vim.keymap.set("n", "grr", telescope_builtin.lsp_references, { buffer = buf, desc = "[G]oto [R]eferences" })
        vim.keymap.set(
            "n",
            "gri",
            telescope_builtin.lsp_implementations,
            { buffer = buf, desc = "[G]oto [I]mplementation" }
        )
        vim.keymap.set("n", "grd", telescope_builtin.lsp_definitions, { buffer = buf, desc = "[G]oto [D]efinition" })
        vim.keymap.set(
            "n",
            "grs",
            telescope_builtin.lsp_document_symbols,
            { buffer = buf, desc = "Open Document Symbols" }
        )
        vim.keymap.set(
            "n",
            "grw",
            telescope_builtin.lsp_dynamic_workspace_symbols,
            { buffer = buf, desc = "Open Workspace Symbols" }
        )
        vim.keymap.set(
            "n",
            "grt",
            telescope_builtin.lsp_type_definitions,
            { buffer = buf, desc = "[G]oto [T]ype Definition" }
        )
    end,
})

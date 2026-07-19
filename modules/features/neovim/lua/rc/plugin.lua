-- [nfnl] fnl/rc/plugin.fnl
local lazy = require("lazy")
local function config_require_str(name)
	return ("require('rc.plugin." .. name .. "')")
end
local function eval(str)
	return assert(load(str))
end
local function mod(name)
	return eval(config_require_str(name))
end
return lazy.setup({
	{ "folke/lazy.nvim", lazy = true },
	{
		"Olical/nfnl",
		dir = vim.env.DOTNIX_NVIM_NFNL,
		name = "nfnl",
		ft = { "fennel" },
		cmd = "NfnlCompileAllFiles",
		config = mod("nfnl"),
	},
	{ "windwp/nvim-autopairs", config = mod("autopairs") },
	{ "windwp/nvim-ts-autotag", config = mod("autotag") },
	{
		"yetone/avante.nvim",
		event = "VeryLazy",
		opts = { provider = "copilot" },
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"stevearc/dressing.nvim",
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			"nvim-tree/nvim-web-devicons",
			{ "zbirenbaum/copilot.lua", opts = { suggestion = { enabled = false }, panel = { enabled = false } } },
			{
				"HakonHarnes/img-clip.nvim",
				event = "VeryLazy",
				opts = {
					default = {
						drag_and_drop = { insert_mode = true },
						use_absolute_path = true,
						embed_image_as_base64 = false,
						prompt_for_file_name = false,
					},
				},
			},
			{
				"MeanderingProgrammer/render-markdown.nvim",
				opts = { file_types = { "markdown", "Avante" } },
				ft = { "markdown", "Avante" },
			},
		},
	},
	{
		"saghen/blink.cmp",
		version = "1.*",
		opts = {
			keymap = { preset = "enter" },
			appearance = { nerd_font_variant = "mono" },
			completion = { documentation = { auto_show = true } },
			sources = { default = { "lsp", "path", "snippets", "buffer" } },
		},
		lazy = false,
	},
	{ "akinsho/bufferline.nvim", config = mod("bufferline") },
	{ "stevearc/conform.nvim", config = mod("conform") },
	{ "github/copilot.vim" },
	{
		"akinsho/git-conflict.nvim",
		version = "*",
		event = "BufReadPre",
		keys = { { "<leader>gx", "<cmd>GitConflictListQf<cr>", desc = "List Conflicts (QuickFix)" } },
		config = mod("git-conflict"),
	},
	{ "lewis6991/gitsigns.nvim", config = mod("gitsigns") },
	{ "rebelot/kanagawa.nvim", priority = 1000, config = mod("kanagawa"), lazy = false },
	{ "nvim-lualine/lualine.nvim", dependencies = { "nvim-tree/nvim-web-devicons" }, config = mod("lualine") },
	{ "mattn/vim-maketable", cmd = { "MakeTable", "UnmakeTable" } },
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		dependencies = { "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons", "MunifTanjim/nui.nvim" },
		keys = {
			{ "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Toggle Explorer" },
			{ "<leader>o", "<cmd>Neotree focus<cr>", desc = "Focus Explorer" },
		},
		config = mod("neo-tree"),
		lazy = false,
	},
	{
		"NeogitOrg/neogit",
		dependencies = { "nvim-lua/plenary.nvim", "sindrets/diffview.nvim", "nvim-telescope/telescope.nvim" },
		cmd = "Neogit",
		keys = {
			{ "<leader>gg", "<cmd>Neogit<cr>", desc = "Neogit" },
			{ "<leader>gc", "<cmd>Neogit commit<cr>", desc = "Neogit commit" },
			{ "<leader>gP", "<cmd>Neogit push<cr>", desc = "Neogit push" },
			{ "<leader>gp", "<cmd>Neogit pull<cr>", desc = "Neogit pull" },
		},
		config = mod("neogit"),
	},
	{
		"sindrets/diffview.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
		keys = {
			{ "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diffview Open" },
			{ "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "File History (current)" },
			{ "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "File History (all)" },
			{ "<leader>gq", "<cmd>DiffviewClose<cr>", desc = "Diffview Close" },
		},
		config = mod("diffview"),
	},
	{
		"folke/noice.nvim",
		event = "VeryLazy",
		dependencies = { "MunifTanjim/nui.nvim", "rcarriga/nvim-notify" },
		opts = {
			lsp = {
				override = {
					["vim.lsp.util.convert_input_to_markdown_lines"] = true,
					["vim.lsp.util.stylize_markdown"] = true,
					["cmp.entry.get_documentation"] = true,
				},
			},
			presets = {
				bottom_search = true,
				command_palette = true,
				long_message_to_split = true,
				inc_rename = false,
				lsp_doc_border = false,
			},
		},
	},
	{ "mfussenegger/nvim-lint", config = mod("nvim-lint") },
	{ "IogaMaster/neocord", event = "VeryLazy", opts = {} },
	{ "stevearc/oil.nvim", opts = {}, dependencies = { { "echasnovski/mini.icons", opts = {} } } },
	{ "Daydreamer-riri/catalog-lens.nvim", opts = { enabled = true, namedCatalogsColors = true } },
	{ dir = vim.env.RUSTOWL_NVIM, name = "rustowl", opts = {}, lazy = false },
	{
		"folke/snacks.nvim",
		priority = 1000,
		opts = {
			dashboard = {
				enabled = true,
				preset = {
					header = "\n\226\150\136\226\150\136\226\150\136\226\149\151   \226\150\136\226\150\136\226\149\151\226\150\136\226\150\136\226\150\136\226\150\136\226\150\136\226\150\136\226\150\136\226\149\151 \226\150\136\226\150\136\226\150\136\226\150\136\226\150\136\226\150\136\226\149\151 \226\150\136\226\150\136\226\149\151   \226\150\136\226\150\136\226\149\151\226\150\136\226\150\136\226\149\151\226\150\136\226\150\136\226\150\136\226\149\151   \226\150\136\226\150\136\226\150\136\226\149\151\n\226\150\136\226\150\136\226\150\136\226\150\136\226\149\151  \226\150\136\226\150\136\226\149\145\226\150\136\226\150\136\226\149\148\226\149\144\226\149\144\226\149\144\226\149\144\226\149\157\226\150\136\226\150\136\226\149\148\226\149\144\226\149\144\226\149\144\226\150\136\226\150\136\226\149\151\226\150\136\226\150\136\226\149\145   \226\150\136\226\150\136\226\149\145\226\150\136\226\150\136\226\149\145\226\150\136\226\150\136\226\150\136\226\150\136\226\149\151 \226\150\136\226\150\136\226\150\136\226\150\136\226\149\145\n\226\150\136\226\150\136\226\149\148\226\150\136\226\150\136\226\149\151 \226\150\136\226\150\136\226\149\145\226\150\136\226\150\136\226\150\136\226\150\136\226\150\136\226\149\151  \226\150\136\226\150\136\226\149\145   \226\150\136\226\150\136\226\149\145\226\150\136\226\150\136\226\149\145   \226\150\136\226\150\136\226\149\145\226\150\136\226\150\136\226\149\145\226\150\136\226\150\136\226\149\148\226\150\136\226\150\136\226\150\136\226\150\136\226\149\148\226\150\136\226\150\136\226\149\145\n\226\150\136\226\150\136\226\149\145\226\149\154\226\150\136\226\150\136\226\149\151\226\150\136\226\150\136\226\149\145\226\150\136\226\150\136\226\149\148\226\149\144\226\149\144\226\149\157  \226\150\136\226\150\136\226\149\145   \226\150\136\226\150\136\226\149\145\226\149\154\226\150\136\226\150\136\226\149\151 \226\150\136\226\150\136\226\149\148\226\149\157\226\150\136\226\150\136\226\149\145\226\150\136\226\150\136\226\149\145\226\149\154\226\150\136\226\150\136\226\149\148\226\149\157\226\150\136\226\150\136\226\149\145\n\226\150\136\226\150\136\226\149\145 \226\149\154\226\150\136\226\150\136\226\150\136\226\150\136\226\149\145\226\150\136\226\150\136\226\150\136\226\150\136\226\150\136\226\150\136\226\150\136\226\149\151\226\149\154\226\150\136\226\150\136\226\150\136\226\150\136\226\150\136\226\150\136\226\149\148\226\149\157 \226\149\154\226\150\136\226\150\136\226\150\136\226\150\136\226\149\148\226\149\157 \226\150\136\226\150\136\226\149\145\226\150\136\226\150\136\226\149\145 \226\149\154\226\149\144\226\149\157 \226\150\136\226\150\136\226\149\145\n\226\149\154\226\149\144\226\149\157  \226\149\154\226\149\144\226\149\144\226\149\144\226\149\157\226\149\154\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\157 \226\149\154\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\157   \226\149\154\226\149\144\226\149\144\226\149\144\226\149\157  \226\149\154\226\149\144\226\149\157\226\149\154\226\149\144\226\149\157     \226\149\154\226\149\144\226\149\157\n          ",
					keys = {
						{
							icon = " ",
							key = "f",
							desc = "Find File",
							action = ":lua Snacks.dashboard.pick('files')",
						},
						{ icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
						{
							icon = " ",
							key = "g",
							desc = "Find Text",
							action = ":lua Snacks.dashboard.pick('live_grep')",
						},
						{
							icon = " ",
							key = "r",
							desc = "Recent Files",
							action = ":lua Snacks.dashboard.pick('oldfiles')",
						},
						{
							icon = " ",
							key = "c",
							desc = "Config",
							action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
						},
						{ icon = "\243\176\146\178 ", key = "l", desc = "Lazy", action = ":Lazy" },
						{ icon = " ", key = "q", desc = "Quit", action = ":qa" },
					},
				},
				sections = {
					{ section = "header" },
					{ section = "keys", gap = 1, padding = 1 },
					{ section = "recent_files", title = "Recent Files", limit = 8, padding = 1 },
					{ section = "projects", title = "Projects", limit = 8, padding = 1 },
					{ section = "startup" },
				},
			},
		},
		lazy = false,
	},
	{
		"nvim-telescope/telescope.nvim",
		dependencies = { "nvim-lua/plenary.nvim", { "nvim-telescope/telescope-fzf-native.nvim", build = "make" } },
		cmd = "Telescope",
		keys = {
			{ "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
			{ "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live Grep" },
			{ "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
			{ "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent Files" },
			{ "<leader>gs", "<cmd>Telescope git_status<cr>", desc = "Git Status (changed files)" },
		},
		config = mod("telescope"),
	},
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		event = { "BufReadPre", "BufNewFile" },
		main = "nvim-treesitter",
		config = mod("treesitter"),
	},
	{ "wakatime/vim-wakatime" },
	{ "folke/which-key.nvim", event = "VeryLazy", opts = { plugins = { spelling = true } } },
}, { defaults = { lazy = false }, checker = { enabled = true, notify = false } })

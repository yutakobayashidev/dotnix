return {
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		},
		cmd = "Telescope",
		keys = {
			{ "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
			{ "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live Grep" },
			{ "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
			{ "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent Files" },
			{ "<leader>gs", "<cmd>Telescope git_status<cr>", desc = "Git Status (changed files)" },
		},
		config = function()
			local telescope = require("telescope")
			local fzf_path = vim.env.TELESCOPE_FZF_NATIVE
			if fzf_path then
				vim.opt.runtimepath:prepend(fzf_path)
			end
			telescope.setup({
				defaults = {
					file_ignore_patterns = { "node_modules", ".git/" },
					-- neo-treeなどの特殊なウィンドウを避けてファイルを開く
					get_selection_window = function()
						local wins = vim.api.nvim_list_wins()
						for _, win in ipairs(wins) do
							local buf = vim.api.nvim_win_get_buf(win)
							local ft = vim.api.nvim_get_option_value("filetype", { buf = buf })
							local buftype = vim.api.nvim_get_option_value("buftype", { buf = buf })
							-- 通常のバッファ（buftypeが空）で、特殊なfiletypeでないものを選択
							if buftype == "" and ft ~= "neo-tree" and ft ~= "TelescopePrompt" then
								return win
							end
						end
						return 0
					end,
				},
			})
			pcall(telescope.load_extension, "fzf")
		end,
	},
}

return {
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		event = { "BufReadPre", "BufNewFile" },
		main = "nvim-treesitter",
		init = function()
			local treesitter_grammars = vim.env.TREESITTER_GRAMMARS
			if treesitter_grammars then
				vim.opt.runtimepath:append(treesitter_grammars)
			end
		end,
		opts = {
			auto_install = false, -- Grammars are provided by Nix
			sync_install = false,
			ensure_installed = { "nix" },
			highlight = { enable = true },
			indent = { enable = true },
		},
	},
}

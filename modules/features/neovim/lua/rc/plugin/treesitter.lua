-- [nfnl] fnl/rc/plugin/treesitter.fnl
if vim.env.TREESITTER_GRAMMARS then
	vim.opt.runtimepath:append(vim.env.TREESITTER_GRAMMARS)
else
end
if vim.env.TREESITTER_MOONBIT then
	vim.opt.runtimepath:append(vim.env.TREESITTER_MOONBIT)
else
end
local treesitter = require("nvim-treesitter")
return treesitter.setup({
	ensure_installed = { "nix" },
	highlight = { enable = true, disable = { "vim" } },
	indent = { enable = true },
	auto_install = false,
	sync_install = false,
})

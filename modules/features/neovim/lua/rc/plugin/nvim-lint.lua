-- [nfnl] fnl/rc/plugin/nvim-lint.fnl
local lint = require("lint")
lint.linters_by_ft = {
	javascript = { "eslint_d" },
	javascriptreact = { "eslint_d" },
	typescript = { "eslint_d" },
	typescriptreact = { "eslint_d" },
}
local function _1_()
	return lint.try_lint()
end
return vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, { callback = _1_ })

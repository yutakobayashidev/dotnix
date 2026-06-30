-- [nfnl] fnl/rc/plugin/diffview.fnl
local diffview = require("diffview")
local function _1_()
	return pcall(vim.cmd, "Neotree close")
end
local function _2_()
	local function _3_()
		return pcall(vim.cmd, "Neotree show")
	end
	return vim.schedule(_3_)
end
return diffview.setup({
	enhanced_diff_hl = true,
	use_icons = true,
	view = { default = { layout = "diff2_vertical" }, file_history = { layout = "diff2_vertical" } },
	hooks = { view_opened = _1_, view_closed = _2_ },
})

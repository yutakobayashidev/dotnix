-- [nfnl] fnl/rc/plugin/bufferline.fnl
local bufferline = require("bufferline")
bufferline.setup({
	options = {
		mode = "tabs",
		separator_style = "slant",
		color_icons = true,
		always_show_bufferline = false,
		show_buffer_close_icons = false,
		show_close_icon = false,
	},
	highlights = {
		separator = { fg = "#073642", bg = "#002b36" },
		separator_selected = { fg = "#073642" },
		background = { fg = "#657b83", bg = "#002b36" },
		buffer_selected = { fg = "#fdf6e3", bold = true },
		fill = { bg = "#073642" },
	},
})
vim.keymap.set("n", "<Tab>", "<Cmd>BufferLineCycleNext<CR>", {})
vim.keymap.set("n", "<S-Tab>", "<Cmd>BufferLineCyclePrev<CR>", {})
return vim.keymap.set("n", "<leader>tc", "<Cmd>tabclose<CR>", { desc = "Close tab" })

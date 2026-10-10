-- [nfnl] fnl/rc/plugin/neogit.fnl
local neogit = require("neogit")
neogit.setup({ kind = "split", integrations = { diffview = true, telescope = true } })
local neotree_open = false
local group = vim.api.nvim_create_augroup("NeogitNeoTreeIntegration", { clear = true })
local function _1_()
	local found = false
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local buf = vim.api.nvim_win_get_buf(win)
		local ft = vim.bo[buf].filetype
		if not found and (ft == "neo-tree") then
			found = true
			neotree_open = true
			vim.cmd("Neotree close")
		else
		end
	end
	return nil
end
vim.api.nvim_create_autocmd("FileType", { group = group, pattern = "NeogitStatus", callback = _1_ })
local function _3_()
	if neotree_open then
		local function _4_()
			return vim.cmd("Neotree show")
		end
		vim.schedule(_4_)
		neotree_open = false
		return nil
	else
		return nil
	end
end
return vim.api.nvim_create_autocmd("BufWinLeave", { group = group, pattern = "NeogitStatus", callback = _3_ })

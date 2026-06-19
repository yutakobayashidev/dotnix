-- [nfnl] fnl/rc/plugin/telescope.fnl
local telescope = require("telescope")
if vim.env.TELESCOPE_FZF_NATIVE then
  vim.opt.runtimepath:prepend(vim.env.TELESCOPE_FZF_NATIVE)
else
end
local function selection_window()
  local selected = 0
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    local ft = vim.api.nvim_get_option_value("filetype", {buf = buf})
    local buftype = vim.api.nvim_get_option_value("buftype", {buf = buf})
    if ((buftype == "") and (ft ~= "neo-tree") and (ft ~= "TelescopePrompt") and (selected == 0)) then
      selected = win
    else
    end
  end
  return selected
end
telescope.setup({defaults = {file_ignore_patterns = {"node_modules", ".git/"}, get_selection_window = selection_window}})
return pcall(telescope.load_extension, "fzf")

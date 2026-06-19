-- [nfnl] fnl/rc/autocmds.fnl
local transparent_groups = {"Normal", "NormalNC", "NormalFloat", "SignColumn", "EndOfBuffer", "NeoTreeNormal", "NeoTreeNormalNC"}
local immediate_transparent_groups = {"Normal", "NormalNC", "NormalFloat", "SignColumn", "EndOfBuffer"}
local function clear_backgrounds(groups)
  for _, group in ipairs(groups) do
    vim.api.nvim_set_hl(0, group, {bg = "NONE", ctermbg = "NONE"})
  end
  return nil
end
do
  local group_2_auto = vim.api.nvim_create_augroup("transparent-background", {clear = true})
  local function _1_()
    return clear_backgrounds(transparent_groups)
  end
  vim.api.nvim_create_autocmd({"ColorScheme"}, {callback = _1_, group = group_2_auto})
end
clear_backgrounds(immediate_transparent_groups)
local group_2_auto = vim.api.nvim_create_augroup("highlight-yank", {clear = true})
local function _2_()
  return vim.highlight.on_yank()
end
return vim.api.nvim_create_autocmd({"TextYankPost"}, {callback = _2_, group = group_2_auto})

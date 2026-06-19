-- [nfnl] fnl/rc/plugin/git-conflict.fnl
local git_conflict = require("git-conflict")
git_conflict.setup({default_mappings = true, default_commands = true, list_opener = "copen", highlights = {incoming = "DiffAdd", current = "DiffText"}, disable_diagnostics = false})
local function _1_()
  return vim.notify("\227\130\179\227\131\179\227\131\149\227\131\170\227\130\175\227\131\136\227\129\140\230\164\156\229\135\186\227\129\149\227\130\140\227\129\190\227\129\151\227\129\159", vim.log.levels.WARN)
end
return vim.api.nvim_create_autocmd("User", {pattern = "GitConflictDetected", callback = _1_})

-- [nfnl] fnl/rc/plugin/neo-tree.fnl
local neo_tree = require("neo-tree")
local function focus_parent(state)
  local node = state.tree:get_node()
  local parent_id = node:get_parent_id()
  if parent_id then
    local renderer = require("neo-tree.ui.renderer")
    local focused = renderer.focus_node(state, parent_id)
    if not focused then
      local commands = require("neo-tree.sources.filesystem.commands")
      return commands.navigate_up(state)
    else
      return nil
    end
  else
    return nil
  end
end
neo_tree.setup({filesystem = {follow_current_file = {enabled = true}, use_libuv_file_watcher = true, filtered_items = {visible = true, hide_gitignored = true, hide_dotfiles = false}, commands = {focus_parent = focus_parent}, window = {mappings = {["<bs>"] = "focus_parent"}}}, window = {width = 30, mappings = {["<space>"] = "none", ["<cr>"] = "open_tabnew"}}})
local function _3_()
  if (vim.fn.argc() > 0) then
    return vim.cmd("Neotree show")
  else
    return nil
  end
end
return vim.api.nvim_create_autocmd("VimEnter", {callback = _3_})

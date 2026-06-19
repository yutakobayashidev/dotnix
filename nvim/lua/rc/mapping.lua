-- [nfnl] fnl/rc/mapping.fnl
vim.keymap.set("n", "<C-h>", "<C-w>h", {desc = "Go to left window"})
vim.keymap.set("n", "<C-j>", "<C-w>j", {desc = "Go to lower window"})
vim.keymap.set("n", "<C-k>", "<C-w>k", {desc = "Go to upper window"})
vim.keymap.set("n", "<C-l>", "<C-w>l", {desc = "Go to right window"})
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", {desc = "Clear search highlight"})
do
  vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", {expr = true, silent = true})
  vim.keymap.set("x", "j", "v:count == 0 ? 'gj' : 'j'", {expr = true, silent = true})
end
do
  vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", {expr = true, silent = true})
  vim.keymap.set("x", "k", "v:count == 0 ? 'gk' : 'k'", {expr = true, silent = true})
end
vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, {desc = "Code actions"})
vim.keymap.set("n", "gd", vim.lsp.buf.definition, {desc = "Go to definition"})
vim.keymap.set("n", "gr", vim.lsp.buf.references, {desc = "Find references"})
return vim.keymap.set("n", "K", vim.lsp.buf.hover, {desc = "Hover documentation"})

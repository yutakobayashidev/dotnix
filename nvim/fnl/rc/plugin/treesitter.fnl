(when vim.env.TREESITTER_GRAMMARS
  (vim.opt.runtimepath:append vim.env.TREESITTER_GRAMMARS))

(when vim.env.TREESITTER_MOONBIT
  (vim.opt.runtimepath:append vim.env.TREESITTER_MOONBIT))

(local treesitter (require :nvim-treesitter))

(treesitter.setup
  {:auto_install false
   :sync_install false
   :ensure_installed [:nix]
   :highlight {:enable true}
   :indent {:enable true}})

(local telescope (require :telescope))

(when vim.env.TELESCOPE_FZF_NATIVE
  (vim.opt.runtimepath:prepend vim.env.TELESCOPE_FZF_NATIVE))

(fn selection-window []
  (var selected 0)
  (each [_ win (ipairs (vim.api.nvim_list_wins))]
    (let [buf (vim.api.nvim_win_get_buf win)
          ft (vim.api.nvim_get_option_value :filetype {:buf buf})
          buftype (vim.api.nvim_get_option_value :buftype {:buf buf})]
      (when (and (= buftype "")
                 (~= ft "neo-tree")
                 (~= ft "TelescopePrompt")
                 (= selected 0))
        (set selected win))))
  selected)

(telescope.setup
  {:defaults {:file_ignore_patterns [:node_modules ".git/"]
              :get_selection_window selection-window}})

(pcall telescope.load_extension :fzf)

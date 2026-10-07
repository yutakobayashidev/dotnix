(local neogit (require :neogit))

(neogit.setup
  {:kind :split
   :integrations {:diffview true
                  :telescope true}})

(var neotree-open false)
(local group
  (vim.api.nvim_create_augroup
    :NeogitNeoTreeIntegration
    {:clear true}))

(vim.api.nvim_create_autocmd
  :FileType
  {:group group
   :pattern :NeogitStatus
   :callback
   (fn []
     (var found false)
     (each [_ win (ipairs (vim.api.nvim_list_wins))]
       (let [buf (vim.api.nvim_win_get_buf win)
             ft (. vim.bo buf :filetype)]
         (when (and (not found) (= ft "neo-tree"))
           (set found true)
           (set neotree-open true)
           (vim.cmd "Neotree close")))))})

(vim.api.nvim_create_autocmd
  :BufWinLeave
  {:group group
   :pattern :NeogitStatus
   :callback
   (fn []
     (when neotree-open
       (vim.schedule
         (fn []
           (vim.cmd "Neotree show")))
       (set neotree-open false)))})

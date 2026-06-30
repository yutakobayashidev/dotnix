(local git-conflict (require :git-conflict))

(git-conflict.setup
  {:default_mappings true
   :default_commands true
   :disable_diagnostics false
   :list_opener :copen
   :highlights {:incoming :DiffAdd
                :current :DiffText}})

(vim.api.nvim_create_autocmd
  :User
  {:pattern :GitConflictDetected
   :callback (fn []
               (vim.notify
                 "コンフリクトが検出されました"
                 vim.log.levels.WARN))})

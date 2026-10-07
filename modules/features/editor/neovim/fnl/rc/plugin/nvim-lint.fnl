(local lint (require :lint))

(set lint.linters_by_ft
     {:javascript [:eslint_d]
      :javascriptreact [:eslint_d]
      :typescript [:eslint_d]
      :typescriptreact [:eslint_d]})

(vim.api.nvim_create_autocmd
  [:BufEnter :BufWritePost :InsertLeave]
  {:callback (fn []
               (lint.try_lint))})

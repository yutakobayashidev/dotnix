(import-macros {: augroup!} :rc.macros)

(local transparent-groups
  [:Normal
   :NormalNC
   :NormalFloat
   :SignColumn
   :EndOfBuffer
   :NeoTreeNormal
   :NeoTreeNormalNC])

(local immediate-transparent-groups
  [:Normal
   :NormalNC
   :NormalFloat
   :SignColumn
   :EndOfBuffer])

(fn clear-backgrounds [groups]
  (each [_ group (ipairs groups)]
    (vim.api.nvim_set_hl 0 group {:bg :NONE
                                  :ctermbg :NONE})))

(augroup!
  transparent-background
  {:events [:ColorScheme]
   :callback (fn []
               (clear-backgrounds transparent-groups))})

(clear-backgrounds immediate-transparent-groups)

(augroup!
  highlight-yank
  {:events [:TextYankPost]
   :callback (fn []
               (vim.highlight.on_yank))})

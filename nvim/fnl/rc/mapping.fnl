(import-macros {: map!} :rc.macros)

(map! [:n] :<C-h> :<C-w>h {:desc "Go to left window"})
(map! [:n] :<C-j> :<C-w>j {:desc "Go to lower window"})
(map! [:n] :<C-k> :<C-w>k {:desc "Go to upper window"})
(map! [:n] :<C-l> :<C-w>l {:desc "Go to right window"})

(map! [:n] :<Esc> "<cmd>nohlsearch<CR>" {:desc "Clear search highlight"})

(map! [:n :x]
      :j
      "v:count == 0 ? 'gj' : 'j'"
      {:expr true
       :silent true})
(map! [:n :x]
      :k
      "v:count == 0 ? 'gk' : 'k'"
      {:expr true
       :silent true})

(map! [:n] :<leader>ca vim.lsp.buf.code_action {:desc "Code actions"})
(map! [:n] :gd vim.lsp.buf.definition {:desc "Go to definition"})
(map! [:n] :gr vim.lsp.buf.references {:desc "Find references"})
(map! [:n] :K vim.lsp.buf.hover {:desc "Hover documentation"})

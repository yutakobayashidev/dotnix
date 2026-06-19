(local cache {})
(local cache-order [])
(local bin-path
  (or vim.env.PRETTY_TS_ERRORS_BIN
      "pretty-ts-errors-markdown"))

(fn format-ts-diagnostic [diagnostic]
  (if (and (~= diagnostic.source "ts")
           (~= diagnostic.source "typescript"))
      diagnostic.message
      (let [cache-key (.. diagnostic.message
                          (or diagnostic.code ""))
            cached (. cache cache-key)]
        (if cached
            cached
            (let [diagnostic-json (vim.json.encode diagnostic)
                  escaped (diagnostic-json:gsub "'" "'\\''")
                  command (.. bin-path
                              " -i '"
                              escaped
                              "' 2>/dev/null")
                  handle (io.popen command)]
              (if handle
                  (let [prettified (handle:read "*a")]
                    (handle:close)
                    (if (and prettified (~= prettified ""))
                        (let [trimmed
                              (prettified:gsub "^%s*(.-)%s*$" "%1")
                              without-links
                              (trimmed:gsub
                                "%[([^%]]+)%]%(([^%)]+)%)"
                                "%1")
                              without-open-marker
                              (without-links:gsub "```%w*\n" "")
                              result
                              (without-open-marker:gsub "\n```" "")]
                          (when (>= (length cache-order) 3)
                            (let [oldest (table.remove cache-order 1)]
                              (tset cache oldest nil)))
                          (tset cache cache-key result)
                          (table.insert cache-order cache-key)
                          result)
                        diagnostic.message))
                  diagnostic.message))))))

(vim.diagnostic.config
  {:float {:format format-ts-diagnostic
           :border :rounded
           :source true}
   :virtual_text
   {:spacing 4
    :prefix "●"
    :format (fn [diagnostic]
              (string.format
                "%s"
                (diagnostic.message:match "^[^\n]*")))}
   :signs true
   :underline true
   :severity_sort true})

(vim.api.nvim_create_autocmd
  :CursorHold
  {:callback (fn []
               (vim.diagnostic.open_float
                 nil
                 {:focusable false}))})

(set vim.opt.updatetime 300)

(set vim.lsp.config.vtsls
     {:cmd [:vtsls :--stdio]
      :filetypes [:javascript
                  :javascriptreact
                  :typescript
                  :typescriptreact]
      :root_markers [:tsconfig.json
                     :jsconfig.json
                     :package.json
                     :.git]
      :settings {:typescript
                 {:preferences
                  {:importModuleSpecifier :non-relative}}}})

(set vim.lsp.config.astro
     {:cmd [:astro-ls :--stdio]
      :filetypes [:astro]
      :root_markers [:package.json :tsconfig.json :.git]})

(set vim.lsp.config.emmet_ls
     {:cmd [:emmet-language-server :--stdio]
      :filetypes [:html
                  :css
                  :scss
                  :javascriptreact
                  :typescriptreact
                  :vue
                  :svelte
                  :astro]
      :root_markers [:.git]})

(set vim.lsp.config.prismals
     {:cmd [:prisma-language-server :--stdio]
      :filetypes [:prisma]
      :root_markers [:schema.prisma :.git]})

(set vim.lsp.config.stylelint_lsp
     {:cmd [:stylelint-lsp :--stdio]
      :filetypes [:css :scss :less :vue :svelte]
      :root_markers [:.stylelintrc
                     :.stylelintrc.json
                     :stylelint.config.js
                     :.git]})

(set vim.lsp.config.svelte
     {:cmd [:svelteserver :--stdio]
      :filetypes [:svelte]
      :root_markers [:svelte.config.js :package.json :.git]})

(set vim.lsp.config.tailwindcss
     {:cmd [:tailwindcss-language-server :--stdio]
      :filetypes [:html
                  :css
                  :scss
                  :javascript
                  :javascriptreact
                  :typescript
                  :typescriptreact
                  :vue
                  :svelte
                  :astro]
      :root_markers [:tailwind.config.js
                     :tailwind.config.ts
                     :postcss.config.js
                     :vite.config.ts
                     :.git]})

(set vim.lsp.config.html
     {:cmd [:vscode-html-language-server :--stdio]
      :filetypes [:html]
      :root_markers [:.git]})

(set vim.lsp.config.cssls
     {:cmd [:vscode-css-language-server :--stdio]
      :filetypes [:css :scss :less]
      :root_markers [:.git]})

(set vim.lsp.config.jsonls
     {:cmd [:vscode-json-language-server :--stdio]
      :filetypes [:json :jsonc]
      :root_markers [:.git]})

(set vim.lsp.config.volar
     {:cmd [:vue-language-server :--stdio]
      :filetypes [:vue]
      :root_markers [:vue.config.js
                     :nuxt.config.js
                     :nuxt.config.ts
                     :package.json
                     :.git]})

(set vim.lsp.config.yamlls
     {:cmd [:yaml-language-server :--stdio]
      :filetypes [:yaml :yaml.docker-compose]
      :root_markers [:.git]})

(set vim.lsp.config.version_lsp
     {:cmd [:version-lsp]
      :filetypes [:json :toml :yaml]
      :root_markers [:package.json
                     :pnpm-workspace.yaml
                     :Cargo.toml
                     :go.mod
                     :.git]})

(set vim.lsp.config.moonbit
     {:cmd [:moonbit-lsp]
      :filetypes [:moonbit]
      :root_markers [:moon.mod.json :.git]})

(set vim.lsp.config.fennel_ls
     {:cmd [:fennel-ls]
      :filetypes [:fennel]
      :root_markers [:.nfnl.fnl :flsproject.fnl :.git]})

(vim.filetype.add
  {:extension {:mbt :moonbit}})

(vim.lsp.enable
  [:vtsls
   :astro
   :emmet_ls
   :prismals
   :stylelint_lsp
   :svelte
   :tailwindcss
   :html
   :cssls
   :jsonls
   :eslint
   :volar
   :yamlls
   :version_lsp
   :moonbit
   :fennel_ls])

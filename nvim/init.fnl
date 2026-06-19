(local lazypath (.. (vim.fn.stdpath :data) "/lazy"))
(local init-source (. (debug.getinfo 1 "S") :source))
(local config-root
  (vim.fs.dirname (init-source:sub 2)))

(set vim.g.dotnix_nvim_config_root config-root)

(vim.secure.trust
  {:action :allow
   :path (.. config-root "/.nfnl.fnl")})

(fn ensure [user repo branch]
  (let [install-path (string.format "%s/%s" lazypath repo)]
    (when (> (vim.fn.empty (vim.fn.glob install-path)) 0)
      (let [args [:git :clone "--filter=blob:none" "--single-branch"]]
        (when branch
          (table.insert args :--branch)
          (table.insert args branch))
        (table.insert
          args
          (string.format "https://github.com/%s/%s" user repo))
        (table.insert args install-path)
        (let [result (vim.fn.system args)]
        (when (~= vim.v.shell_error 0)
          (error result)))))
    (vim.opt.runtimepath:prepend install-path)))

(ensure :folke :lazy.nvim :stable)
(ensure :Olical :nfnl)

(require :rc.init)

(fn compile-all-files []
  (let [nfnl (require :nfnl.api)
        config-root vim.g.dotnix_nvim_config_root
        results
        (assert
          (nfnl.compile-all-files config-root)
          "nfnl did not find a project configuration")]
    (each [_ result (ipairs results)]
      (when (= result.status :compilation-error)
        (error result.error)))
    results))

(vim.api.nvim_create_user_command
  :NfnlCompileAllFiles
  compile-all-files
  {})

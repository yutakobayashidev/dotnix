;; fennel-ls: macro-file
;; [nfnl-macro]

(fn map! [modes from to opts]
  (let [out []]
    (each [_ mode (ipairs modes)]
      (table.insert out `(vim.keymap.set ,mode ,from ,to ,opts)))
    (if (> (length out) 1)
        `(do ,(unpack out))
        `,(unpack out))))

(fn augroup! [name ...]
  `(let [group# (vim.api.nvim_create_augroup
                  ,(tostring name)
                  {:clear true})]
     ,(let [cmds (icollect [_ cmd (ipairs [...])]
                   `(vim.api.nvim_create_autocmd
                      ,cmd.events
                      {:pattern ,cmd.pattern
                       :group group#
                       :buffer ,cmd.buffer
                       :command ,cmd.command
                       :callback ,cmd.callback}))]
        (if (> (length cmds) 1)
            `(do ,(unpack cmds))
            `,(unpack cmds)))))

{: map!
 : augroup!}

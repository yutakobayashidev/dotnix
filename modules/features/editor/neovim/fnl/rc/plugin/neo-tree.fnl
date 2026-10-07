(local neo-tree (require :neo-tree))

(fn focus-parent [state]
  (let [node (state.tree:get_node)
        parent-id (node:get_parent_id)]
    (when parent-id
      (let [renderer (require :neo-tree.ui.renderer)
            focused (renderer.focus_node state parent-id)]
        (when (not focused)
          (let [commands (require :neo-tree.sources.filesystem.commands)]
            (commands.navigate_up state)))))))

(neo-tree.setup
  {:filesystem
   {:follow_current_file {:enabled true}
    :use_libuv_file_watcher true
    :filtered_items {:visible true
                     :hide_dotfiles false
                     :hide_gitignored true}
    :commands {:focus_parent focus-parent}
    :window {:mappings {:<bs> :focus_parent}}}
   :window {:width 30
            :mappings {:<space> :none
                       :<cr> :open_tabnew}}})

(vim.api.nvim_create_autocmd
  :VimEnter
  {:callback (fn []
               (when (> (vim.fn.argc) 0)
                 (vim.cmd "Neotree show")))})

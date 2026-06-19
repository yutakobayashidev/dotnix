(local diffview (require :diffview))

(diffview.setup
  {:enhanced_diff_hl true
   :use_icons true
   :view {:default {:layout :diff2_vertical}
          :file_history {:layout :diff2_vertical}}
   :hooks
   {:view_opened
    (fn []
      (pcall vim.cmd "Neotree close"))
    :view_closed
    (fn []
      (vim.schedule
        (fn []
          (pcall vim.cmd "Neotree show"))))}})

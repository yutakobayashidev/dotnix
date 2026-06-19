(local lazy (require :lazy))

(fn config-require-str [name]
  (.. "require('rc.plugin." name "')"))

(fn eval [str]
  (assert (load str)))

(fn mod [name]
  (-> name config-require-str eval))

(lazy.setup
  [{1 :folke/lazy.nvim
    :lazy true}
   {1 :Olical/nfnl
    :ft [:fennel]
    :cmd :NfnlCompileAllFiles
    :config (mod :nfnl)}
   {1 :windwp/nvim-autopairs
    :config (mod :autopairs)}
   {1 :windwp/nvim-ts-autotag
    :config (mod :autotag)}
   {1 :yetone/avante.nvim
    :event :VeryLazy
    :opts {:provider :copilot}
    :dependencies
    [:nvim-treesitter/nvim-treesitter
     :stevearc/dressing.nvim
     :nvim-lua/plenary.nvim
     :MunifTanjim/nui.nvim
     :nvim-tree/nvim-web-devicons
     {1 :zbirenbaum/copilot.lua
      :opts {:suggestion {:enabled false}
             :panel {:enabled false}}}
     {1 :HakonHarnes/img-clip.nvim
      :event :VeryLazy
      :opts {:default {:embed_image_as_base64 false
                       :prompt_for_file_name false
                       :drag_and_drop {:insert_mode true}
                       :use_absolute_path true}}}
     {1 :MeanderingProgrammer/render-markdown.nvim
      :opts {:file_types [:markdown :Avante]}
      :ft [:markdown :Avante]}]}
   {1 :saghen/blink.cmp
    :lazy false
    :version "1.*"
    :opts {:keymap {:preset :enter}
           :appearance {:nerd_font_variant :mono}
           :completion {:documentation {:auto_show true}}
           :sources {:default [:lsp :path :snippets :buffer]}}}
   {1 :akinsho/bufferline.nvim
    :config (mod :bufferline)}
   {1 :stevearc/conform.nvim
    :config (mod :conform)}
   {1 :github/copilot.vim}
   {1 :akinsho/git-conflict.nvim
    :version "*"
    :event :BufReadPre
    :keys [{1 :<leader>gx
            2 "<cmd>GitConflictListQf<cr>"
            :desc "List Conflicts (QuickFix)"}]
    :config (mod :git-conflict)}
   {1 :lewis6991/gitsigns.nvim
    :config (mod :gitsigns)}
   {1 :rebelot/kanagawa.nvim
    :lazy false
    :priority 1000
    :config (mod :kanagawa)}
   {1 :nvim-lualine/lualine.nvim
    :dependencies [:nvim-tree/nvim-web-devicons]
    :config (mod :lualine)}
   {1 :mattn/vim-maketable
    :cmd [:MakeTable :UnmakeTable]}
   {1 :nvim-neo-tree/neo-tree.nvim
    :branch "v3.x"
    :lazy false
    :dependencies [:nvim-lua/plenary.nvim
                   :nvim-tree/nvim-web-devicons
                   :MunifTanjim/nui.nvim]
    :keys [{1 :<leader>e
            2 "<cmd>Neotree toggle<cr>"
            :desc "Toggle Explorer"}
           {1 :<leader>o
            2 "<cmd>Neotree focus<cr>"
            :desc "Focus Explorer"}]
    :config (mod :neo-tree)}
   {1 :NeogitOrg/neogit
    :dependencies [:nvim-lua/plenary.nvim
                   :sindrets/diffview.nvim
                   :nvim-telescope/telescope.nvim]
    :cmd :Neogit
    :keys [{1 :<leader>gg
            2 "<cmd>Neogit<cr>"
            :desc :Neogit}
           {1 :<leader>gc
            2 "<cmd>Neogit commit<cr>"
            :desc "Neogit commit"}
           {1 :<leader>gP
            2 "<cmd>Neogit push<cr>"
            :desc "Neogit push"}
           {1 :<leader>gp
            2 "<cmd>Neogit pull<cr>"
            :desc "Neogit pull"}]
    :config (mod :neogit)}
   {1 :sindrets/diffview.nvim
    :dependencies [:nvim-tree/nvim-web-devicons]
    :cmd [:DiffviewOpen :DiffviewFileHistory :DiffviewClose]
    :keys [{1 :<leader>gd
            2 "<cmd>DiffviewOpen<cr>"
            :desc "Diffview Open"}
           {1 :<leader>gh
            2 "<cmd>DiffviewFileHistory %<cr>"
            :desc "File History (current)"}
           {1 :<leader>gH
            2 "<cmd>DiffviewFileHistory<cr>"
            :desc "File History (all)"}
           {1 :<leader>gq
            2 "<cmd>DiffviewClose<cr>"
            :desc "Diffview Close"}]
    :config (mod :diffview)}
   {1 :folke/noice.nvim
    :event :VeryLazy
    :dependencies [:MunifTanjim/nui.nvim
                   :rcarriga/nvim-notify]
    :opts {:lsp {:override
                 {"vim.lsp.util.convert_input_to_markdown_lines" true
                  "vim.lsp.util.stylize_markdown" true
                  "cmp.entry.get_documentation" true}}
           :presets {:bottom_search true
                     :command_palette true
                     :long_message_to_split true
                     :inc_rename false
                     :lsp_doc_border false}}}
   {1 :mfussenegger/nvim-lint
    :config (mod :nvim-lint)}
   {1 :stevearc/oil.nvim
    :opts {}
    :dependencies [{1 :echasnovski/mini.icons
                    :opts {}}]}
   {1 :Daydreamer-riri/catalog-lens.nvim
    :opts {:enabled true
           :namedCatalogsColors true}}
   {:dir vim.env.RUSTOWL_NVIM
    :name :rustowl
    :lazy false
    :opts {}}
   {1 :folke/snacks.nvim
    :priority 1000
    :lazy false
    :opts {:dashboard
           {:enabled true
            :preset
            {:header
             "\n███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗\n████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║\n██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║\n██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║\n██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║\n╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝\n          "
             :keys
             [{:icon " "
               :key :f
               :desc "Find File"
               :action ":lua Snacks.dashboard.pick('files')"}
              {:icon " "
               :key :n
               :desc "New File"
               :action ":ene | startinsert"}
              {:icon " "
               :key :g
               :desc "Find Text"
               :action ":lua Snacks.dashboard.pick('live_grep')"}
              {:icon " "
               :key :r
               :desc "Recent Files"
               :action ":lua Snacks.dashboard.pick('oldfiles')"}
              {:icon " "
               :key :c
               :desc :Config
               :action
               ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})"}
              {:icon "󰒲 "
               :key :l
               :desc :Lazy
               :action ":Lazy"}
              {:icon " "
               :key :q
               :desc :Quit
               :action ":qa"}]}
            :sections [{:section :header}
                       {:section :keys
                        :gap 1
                        :padding 1}
                       {:section :recent_files
                        :title "Recent Files"
                        :limit 8
                        :padding 1}
                       {:section :projects
                        :title :Projects
                        :limit 8
                        :padding 1}
                       {:section :startup}]}}}
   {1 :nvim-telescope/telescope.nvim
    :dependencies [:nvim-lua/plenary.nvim
                   {1 :nvim-telescope/telescope-fzf-native.nvim
                    :build :make}]
    :cmd :Telescope
    :keys [{1 :<leader>ff
            2 "<cmd>Telescope find_files<cr>"
            :desc "Find Files"}
           {1 :<leader>fg
            2 "<cmd>Telescope live_grep<cr>"
            :desc "Live Grep"}
           {1 :<leader>fb
            2 "<cmd>Telescope buffers<cr>"
            :desc :Buffers}
           {1 :<leader>fr
            2 "<cmd>Telescope oldfiles<cr>"
            :desc "Recent Files"}
           {1 :<leader>gs
            2 "<cmd>Telescope git_status<cr>"
            :desc "Git Status (changed files)"}]
    :config (mod :telescope)}
   {1 :nvim-treesitter/nvim-treesitter
    :build ":TSUpdate"
    :event [:BufReadPre :BufNewFile]
    :main :nvim-treesitter
    :config (mod :treesitter)}
   {1 :wakatime/vim-wakatime}
   {1 :folke/which-key.nvim
    :event :VeryLazy
    :opts {:plugins {:spelling true}}}]
  {:defaults {:lazy false}
   :checker {:enabled true
             :notify false}})

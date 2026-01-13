return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    lazy = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    keys = {
      { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Toggle Explorer" },
      { "<leader>o", "<cmd>Neotree focus<cr>", desc = "Focus Explorer" },
    },
    config = function()
      require("neo-tree").setup({
        filesystem = {
          follow_current_file = { enabled = true },
          use_libuv_file_watcher = true,
          filtered_items = {
            visible = true,
            hide_dotfiles = false,
            hide_gitignored = true,
          },
          commands = {
            focus_parent = function(state)
              local node = state.tree:get_node()
              local parent_id = node:get_parent_id()
              if not parent_id then
                return
              end
              local focused = require("neo-tree.ui.renderer").focus_node(state, parent_id)
              if not focused then
                require("neo-tree.sources.filesystem.commands").navigate_up(state)
              end
            end,
          },
          window = {
            mappings = {
              ["<bs>"] = "focus_parent",
            },
          },
        },
        window = {
          width = 30,
          mappings = {
            ["<space>"] = "none",
            ["<cr>"] = "open_tabnew",
          },
        },
      })
    end,
    init = function()
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
          if vim.fn.argc() == 0 then
            -- ダッシュボードが表示されない時だけ開く
          else
            vim.cmd("Neotree show")
          end
        end,
      })
    end,
  },
}

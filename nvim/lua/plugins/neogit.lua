return {
  {
    "NeogitOrg/neogit",
    dev = true,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim",
      "nvim-telescope/telescope.nvim",
    },
    cmd = "Neogit",
    keys = {
      { "<leader>gg", "<cmd>Neogit<cr>", desc = "Neogit" },
      { "<leader>gc", "<cmd>Neogit commit<cr>", desc = "Neogit commit" },
      { "<leader>gP", "<cmd>Neogit push<cr>", desc = "Neogit push" },
      { "<leader>gp", "<cmd>Neogit pull<cr>", desc = "Neogit pull" },
    },
    config = function()
      require("neogit").setup({
        kind = "split",
        integrations = {
          diffview = true,
          telescope = true,
        },
      })

      -- Neo-tree integration: close on Neogit open, restore on close
      local neotree_open = false
      local group = vim.api.nvim_create_augroup("NeogitNeoTreeIntegration", { clear = true })

      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = "NeogitStatus",
        callback = function()
          -- Check if neo-tree is open
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            local buf = vim.api.nvim_win_get_buf(win)
            local ft = vim.bo[buf].filetype
            if ft == "neo-tree" then
              neotree_open = true
              vim.cmd("Neotree close")
              break
            end
          end
        end,
      })

      vim.api.nvim_create_autocmd("BufWinLeave", {
        group = group,
        pattern = "NeogitStatus",
        callback = function()
          if neotree_open then
            vim.schedule(function()
              vim.cmd("Neotree show")
            end)
            neotree_open = false
          end
        end,
      })
    end,
  },
  {
    "sindrets/diffview.nvim",
    dev = true,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diffview Open" },
      { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "File History (current)" },
      { "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "File History (all)" },
      { "<leader>gq", "<cmd>DiffviewClose<cr>", desc = "Diffview Close" },
    },
    config = function()
      local actions = require("diffview.actions")
      require("diffview").setup({
        enhanced_diff_hl = true,
        use_icons = true,
        view = {
          default = {
            layout = "diff2_vertical",
          },
          file_history = {
            layout = "diff2_vertical",
          },
        },
        hooks = {
          view_opened = function()
            -- Close neo-tree when diffview opens
            pcall(vim.cmd, "Neotree close")
          end,
          view_closed = function()
            -- Restore neo-tree when diffview closes
            vim.schedule(function()
              pcall(vim.cmd, "Neotree show")
            end)
          end,
        },
      })
    end,
  },
}

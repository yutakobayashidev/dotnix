return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPre", "BufNewFile" },
    main = "nvim-treesitter",
    init = function()
      local treesitter_grammars = vim.env.TREESITTER_GRAMMARS
      if treesitter_grammars then
        vim.opt.runtimepath:prepend(treesitter_grammars)
      end
    end,
    opts = {
      highlight = { enable = true },
      indent = { enable = true },
    },
  },
}

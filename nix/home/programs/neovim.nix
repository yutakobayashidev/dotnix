{ config, pkgs, ... }:

let
  plugins = with pkgs.vimPlugins; [
    lazy-nvim
    which-key-nvim
    oil-nvim
    mini-icons
    copilot-vim
    copilot-lua
    snacks-nvim
    telescope-nvim
    plenary-nvim
    neo-tree-nvim
    nui-nvim
    nvim-web-devicons
    blink-cmp
    vim-wakatime
    noice-nvim
    nvim-notify
    conform-nvim
    nvim-lint
    gitsigns-nvim
    lualine-nvim
    neogit
    diffview-nvim
    nvim-ts-autotag
    nvim-autopairs
    bufferline-nvim
    # avante.nvim and dependencies
    avante-nvim
    dressing-nvim
    img-clip-nvim
    render-markdown-nvim
    nvim-treesitter
  ];
in
{
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    defaultEditor = true;
    withNodeJs = true;

    plugins = plugins;

    extraPackages = with pkgs; [
      prettierd
      eslint_d
    ];

    extraLuaConfig = ''
      vim.g.mapleader = " "
      vim.g.maplocalleader = " "

      -- Transparent background
      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = function()
          local groups = {
            "Normal", "NormalNC", "NormalFloat",
            "SignColumn", "EndOfBuffer",
            "NeoTreeNormal", "NeoTreeNormalNC",
          }
          for _, group in ipairs(groups) do
            vim.api.nvim_set_hl(0, group, { bg = "NONE", ctermbg = "NONE" })
          end
        end,
      })
      -- Apply immediately for default colorscheme
      vim.api.nvim_set_hl(0, "Normal", { bg = "NONE", ctermbg = "NONE" })
      vim.api.nvim_set_hl(0, "NormalNC", { bg = "NONE", ctermbg = "NONE" })
      vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE", ctermbg = "NONE" })
      vim.api.nvim_set_hl(0, "SignColumn", { bg = "NONE", ctermbg = "NONE" })
      vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "NONE", ctermbg = "NONE" })

      require("lazy").setup({
        spec = {
          { import = "plugins" },
        },
        performance = {
          reset_packpath = false,
          rtp = {
            reset = false,
          }
        },
        dev = {
          path = "${
            pkgs.vimUtils.packDir {
              myNeovimPackages = {
                start = plugins;
              };
            }
          }/pack/myNeovimPackages/start",
          patterns = { "" },
        },
        install = {
          missing = false,
        },
      })
    '';
  };

  xdg.configFile."nvim/lua" = {
    recursive = true;
    source = ../../../nvim/lua;
  };
}

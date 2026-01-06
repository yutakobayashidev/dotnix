{ config, pkgs, ... }:

let
  plugins = with pkgs.vimPlugins; [
    lazy-nvim
    which-key-nvim
    oil-nvim
    mini-icons
    copilot-vim
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

    extraLuaConfig = ''
      vim.g.mapleader = " "
      vim.g.maplocalleader = " "

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
          path = "${pkgs.vimUtils.packDir { myNeovimPackages = { start = plugins; }; }}/pack/myNeovimPackages/start",
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
    source = ./nvim/lua;
  };
}

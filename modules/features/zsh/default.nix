_:

{
  flake.modules.homeManager.zsh =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.programs.zsh;
    in
    {
      options.my.programs.zsh.enable = lib.mkEnableOption "zsh configuration";

      config = lib.mkIf cfg.enable {
        programs.direnv = {
          enable = true;
          nix-direnv.enable = true;
        };

        # zsh itself is managed by the linked dotfiles.
        programs.zsh.enable = false;

        home = {
          packages = with pkgs; [
            zsh-abbr
            zsh-autosuggestions
            zsh-syntax-highlighting
            zsh-fzf-tab
            oh-my-zsh
          ];

          file = {
            ".oh-my-zsh".source = "${pkgs.oh-my-zsh}/share/oh-my-zsh";
            ".zsh/plugins/zsh-autosuggestions".source = "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions";
            ".zsh/plugins/zsh-syntax-highlighting".source =
              "${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting";
            ".zsh/plugins/fzf-tab".source = "${pkgs.zsh-fzf-tab}/share/fzf-tab";
            ".zsh/plugins/zsh-abbr".source = "${pkgs.zsh-abbr}/share/zsh/zsh-abbr";
          };
        };
      };
    };
}

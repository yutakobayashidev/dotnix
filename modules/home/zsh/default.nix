{ pkgs, ... }:

{
  # direnv
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # zsh本体はdotfilesで管理するため、Home Managerの設定は無効化
  programs.zsh = {
    enable = false;
  };

  # zshプラグインはHome Managerで管理
  home = {
    packages = with pkgs; [
      zsh-abbr
      zsh-autosuggestions
      zsh-syntax-highlighting
      zsh-fzf-tab
      oh-my-zsh
    ];

    file = {
      # .oh-my-zsh ディレクトリを作成（oh-my-zshが期待する場所）
      ".oh-my-zsh".source = "${pkgs.oh-my-zsh}/share/oh-my-zsh";

      # zshプラグインのパスを設定
      ".zsh/plugins/zsh-autosuggestions".source = "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions";
      ".zsh/plugins/zsh-syntax-highlighting".source =
        "${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting";
      ".zsh/plugins/fzf-tab".source = "${pkgs.zsh-fzf-tab}/share/fzf-tab";
      ".zsh/plugins/zsh-abbr".source = "${pkgs.zsh-abbr}/share/zsh/zsh-abbr";
    };
  };
}

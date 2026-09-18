{ pkgs, ... }:

{
  programs.ghostty = {
    enable = true;
    package = if pkgs.stdenv.hostPlatform.isLinux then pkgs.ghostty else null;
    systemd.enable = false;

    settings = {
      theme = "Catppuccin Macchiato";
      background-opacity = 0.75;
      cursor-color = "#f5bde6";
      cursor-text = "#181926";
      selection-background = "#494d64";
      selection-foreground = "#cad3f5";
      font-family = [
        "JetBrains Mono"
        "Noto Sans Mono CJK JP"
      ];
      font-size = 14;
      window-padding-x = 14;
      window-padding-y = 12;
      macos-option-as-alt = true;
      copy-on-select = "clipboard";
      unfocused-split-opacity = 0.85;
      shell-integration-features = "no-ssh-env,no-ssh-terminfo";
      bell-features = "system,audio,attention,title";
      quick-terminal-position = "top";
      quick-terminal-size = "98%,100%";
      quick-terminal-autohide = false;
      quick-terminal-keyboard-interactivity = "on-demand";
      gtk-quick-terminal-layer = "top";
      quit-after-last-window-closed = false;
    };
  };
}

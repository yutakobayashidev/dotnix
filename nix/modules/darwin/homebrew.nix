{ ... }:

{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
    };
    # /Applications へのインストールが必要な cask はここで管理
    # brew-nix で管理可能なものは packages-darwin.nix に移動済み
    casks = [
      "ghostty"
      "google-chrome"
      "1password"
      "android-studio"
    ];
  };
}

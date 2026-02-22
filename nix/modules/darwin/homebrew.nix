{ ... }:

{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
    };
    casks = [
      "ghostty"
      "raycast"
      "google-chrome"
      "discord"
      "slack"
      "obsidian"
      "1password"
      "spotify"
      "android-studio"
    ];
  };
}

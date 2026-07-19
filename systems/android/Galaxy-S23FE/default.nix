{ pkgs, ... }:

{
  imports = [ ../common.nix ];

  system.stateVersion = "24.05";
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';
  environment = {
    etcBackupExtension = ".bak";
    etc."resolv.conf".source = ./resolv.conf;
  };
  android-integration = {
    am.enable = true;
    termux-open.enable = true;
    termux-open-url.enable = true;
    xdg-open.enable = true;
  };
  terminal.font = "${pkgs.firge-nerd-font}/share/fonts/firge-nerd/FirgeNerdConsole-Regular.ttf";
  time.timeZone = "Asia/Tokyo";
  user.shell = "${pkgs.zsh}/bin/zsh";
}

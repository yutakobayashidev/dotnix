{ pkgs, onepassword-shell-plugins, ... }:

{
  imports = [
    ./default.nix
    onepassword-shell-plugins.hmModules.default
  ];

  home.homeDirectory = "/Users/yuta";

  programs.onepassword-shell-plugins = {
    enable = true;
    plugins = with pkgs; [
      gh
      awscli2
    ];
  };
}

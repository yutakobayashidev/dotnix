{ pkgs, ... }:

{
  environment.packages = with pkgs; [
    git
    openssh
  ];

  system.stateVersion = "24.05";

  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  home-manager = {
    backupFileExtension = "hm-bak";
    useGlobalPkgs = true;

    config = {
      home.stateVersion = "24.05";
    };
  };
}

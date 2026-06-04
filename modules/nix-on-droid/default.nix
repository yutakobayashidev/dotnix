{ pkgs, ... }:

{
  home-manager = {
    backupFileExtension = "hm-bak";
    useGlobalPkgs = true;

    config = {
      home.stateVersion = "24.05";
    };
  };
}

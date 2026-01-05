{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "yutakobayashidev";
        email = "hi@yutakobayashi.com";
      };
      credential."https://github.com".helper = "!gh auth git-credential";
    };
  };
}

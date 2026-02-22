{ config, pkgs, ... }:

{
  programs.jujutsu = {
    enable = true;
    settings = {
      user = {
        name = "yutakobayashidev";
        email = "hi@yutakobayashi.com";
      };
      aliases = {
        pull = [
          "util"
          "exec"
          "--"
          "sh"
          "-c"
          "jj git fetch && jj rebase -d main"
        ];
        st = [ "status" ];
        l = [
          "log"
          "-n"
          "10"
        ];
        fresh = [
          "new"
          "main"
        ];
      };
      revset-aliases = {
        trunk = "main@origin";
        "trunk()" = "main@origin";
      };
    };
  };
}

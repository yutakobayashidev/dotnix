{ config, pkgs, ... }:

{
  programs.jujutsu = {
    enable = true;
    settings = {
      aliases = {
        pull = ["util" "exec" "--" "sh" "-c" "jj git fetch && jj rebase -d main"];
        st = ["status"];
        l = ["log" "-n" "10"];
        fresh = ["new" "main"];
      };
    };
  };
}

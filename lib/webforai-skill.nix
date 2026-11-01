{ lib, pkgs }:

{
  from = "webforai";
  path = "webforai";
  packages = [ pkgs.webforai ];
  rewriteCommands = false;
  transform =
    { original, ... }:
    builtins.replaceStrings [ "npx webforai-cli" ] [ (lib.getExe pkgs.webforai) ] original;
}

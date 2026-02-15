{ lib, config, helpers, dotfilesDir, ... }:

let
  inherit (config.home) homeDirectory;
  inherit (config.xdg) configHome;
in
{
  home.activation.linkDotfiles = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    ${helpers.activation.mkLinkForce}

    # zsh
    link_force "${dotfilesDir}/zshenv" "${homeDirectory}/.zshenv"
    link_force "${dotfilesDir}/zsh/zshrc" "${homeDirectory}/.zshrc"
    link_force "${dotfilesDir}/zsh" "${configHome}/zsh"
  '';
}

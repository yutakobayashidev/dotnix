{
  lib,
  pkgs,
  config,
  helpers,
  dotfilesDir,
  ...
}:

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

    # Karabiner Elements configuration (macOS only)
    # Restart Karabiner console user server before updating config to prevent keyboard freeze
    # The daemon can enter an inconsistent state if config changes while running
    if [[ "$(uname)" == "Darwin" ]]; then
      if /bin/launchctl list | ${pkgs.gnugrep}/bin/grep -q "org.pqrs.service.agent.karabiner_console_user_server"; then
        echo "Restarting Karabiner console user server before config update..."
        /bin/launchctl kickstart -k gui/$(/usr/bin/id -u)/org.pqrs.service.agent.karabiner_console_user_server 2>/dev/null || true
        sleep 2
      fi
      link_force "${dotfilesDir}/karabiner" "${configHome}/karabiner"
    fi
  '';
}

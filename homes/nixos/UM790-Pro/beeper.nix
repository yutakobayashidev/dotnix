{ inputs, pkgs, ... }:

let
  server = inputs.nur-packages.packages.${pkgs.stdenv.hostPlatform.system}.beeper-server;
in
{
  home.packages = [ pkgs.beeper-cli ];
  home.sessionVariables.BEEPER_SERVER_BIN = "${server}/bin/beeper-server";

  systemd.user.services.beeper-server = {
    Unit.Description = "Beeper headless Client API server";
    Service = {
      ExecStart = "${server}/bin/beeper-server --host=127.0.0.1 --port=23373 --data-dir=%h/.local/state/beeper-server";
      Environment = "BEEPER_SERVER_DATA_DIR=%h/.local/state/beeper-server";
      StateDirectory = "beeper-server";
      StateDirectoryMode = "0700";
      UMask = "0077";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };
}

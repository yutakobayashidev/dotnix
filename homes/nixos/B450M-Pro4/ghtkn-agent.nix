{ lib, pkgs, ... }:

{
  home.sessionVariables.GHTKN_BACKEND = "agent";

  systemd.user.services.ghtkn-agent = {
    Unit = {
      Description = "ghtkn agent";
    };
    Service = {
      ExecStart = "${lib.getExe pkgs.ghtkn} agent start";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}

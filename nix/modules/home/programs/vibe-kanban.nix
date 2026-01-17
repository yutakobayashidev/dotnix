{ pkgs, ... }:

{
  systemd.user.services.vibe-kanban = {
    Unit = {
      Description = "Vibe Kanban - AI Coding Agent Management";
      After = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${pkgs.vibe-kanban}/bin/vibe-kanban";
      Environment = [
        "PORT=3456"
        "BACKEND_PORT=3457"
        "HOST=127.0.0.1"
      ];
      Restart = "on-failure";
      RestartSec = 5;
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}

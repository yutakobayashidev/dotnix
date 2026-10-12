{ pkgs, ... }:

{
  systemd.user.services.orca = {
    Unit.Description = "Orca headless runtime server";
    Service = {
      ExecStart = "${pkgs.xvfb-run}/bin/xvfb-run -a ${pkgs.llm-agents.orca}/bin/orca serve --port 6768 --pairing-address um790-pro.tail29d068.ts.net";
      # The packaged Node runtime entrypoint is missing in Orca 1.4.224.
      Environment = [
        "ORCA_SERVE_RUNTIME=electron"
        "ORCA_STARTUP_DIAGNOSTICS=1"
        "XDG_SESSION_TYPE=x11"
        "ELECTRON_OZONE_PLATFORM_HINT=x11"
      ];
      UnsetEnvironment = [
        "DISPLAY"
        "WAYLAND_DISPLAY"
      ];
      WorkingDirectory = "%h";
      UMask = "0077";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };
}

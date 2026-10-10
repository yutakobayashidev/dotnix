_:

{
  flake.modules.homeManager.mpris-collector =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      python = pkgs.python3.withPackages (ps: [ ps.pygobject3 ]);
      collector = pkgs.writeShellApplication {
        name = "mpris-media-logger";
        text = ''
          export GI_TYPELIB_PATH="${pkgs.glib.out}/lib/girepository-1.0"
          exec ${python}/bin/python3 ${./collector.py} "$@"
        '';
      };
    in
    {
      options.my.services.mpris-collector.enable = lib.mkEnableOption "local MPRIS JSONL recording";
      config = lib.mkIf config.my.services.mpris-collector.enable {
        home.packages = [ collector ];
        systemd.user.services.mpris-media-logger = {
          Unit = {
            Description = "Record local MPRIS media plays to JSONL";
            After = [ "graphical-session-pre.target" ];
            PartOf = [ "graphical-session.target" ];
          };
          Service = {
            ExecStart = lib.getExe collector;
            Restart = "on-failure";
            RestartSec = 5;
            UMask = "0077";
            NoNewPrivileges = true;
          };
          Install.WantedBy = [ "graphical-session.target" ];
        };
      };
    };
}

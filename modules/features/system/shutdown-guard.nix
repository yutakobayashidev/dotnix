{
  flake.modules.nixos.shutdown-guard =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      guardCommand =
        name:
        let
          command = "${config.systemd.package}/bin/${name}";
        in
        lib.hiPrio (
          pkgs.writeShellApplication {
            inherit name;
            text = ''
              if [[ $# == 1 && $1 == --help ]]; then
                exec ${command} "$@"
              fi
            ''
            + lib.optionalString (name == "shutdown") ''
              if [[ $# == 1 && ( $1 == -c || $1 == --show ) ]]; then
                exec ${command} "$@"
              fi
            ''
            + ''
              if [[ ! -t 0 ]]; then
                echo "${name}: hostname confirmation requires a terminal" >&2
                exit 1
              fi

              hostname="$(${pkgs.coreutils}/bin/uname -n)"
              printf 'Type the hostname of the machine to ${name}: ' >&2
              if ! IFS= read -r confirmation || [[ "$confirmation" != "$hostname" ]]; then
                echo "${name}: hostname confirmation failed" >&2
                exit 1
              fi

              exec ${command} "$@"
            '';
          }
        );
    in
    {
      options.my.programs.shutdownGuard.enable =
        lib.mkEnableOption "hostname confirmation before running reboot or shutdown";

      config = lib.mkIf config.my.programs.shutdownGuard.enable {
        # The system profile must select these before the systemd commands.
        environment.systemPackages = map guardCommand [
          "reboot"
          "shutdown"
        ];
      };
    };
}

_:

{
  flake.modules.homeManager."r2-mount" =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      cfg = config.my.services.r2Mount;
      inherit (cfg) mountPoint;
      cacheDir = "${config.xdg.cacheHome}/rclone-r2";
    in
    {
      options.my.services.r2Mount = {
        enable = lib.mkEnableOption "Cloudflare R2 desktop mount";

        accountId = lib.mkOption {
          type = lib.types.str;
          description = "Cloudflare account ID containing the R2 bucket.";
        };

        bucket = lib.mkOption {
          type = lib.types.str;
          description = "R2 bucket to mount.";
        };

        mountPoint = lib.mkOption {
          type = lib.types.str;
          default = "${config.home.homeDirectory}/Cloudflare-R2";
          description = "Local directory where the R2 bucket is mounted.";
        };

        sopsFile = lib.mkOption {
          type = lib.types.path;
          description = ''
            SOPS file containing `r2-access-key-id` and
            `r2-secret-access-key`.
          '';
        };
      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = pkgs.stdenv.hostPlatform.isLinux;
            message = "my.services.r2Mount is supported only on Linux.";
          }
        ];

        home.packages = [ pkgs.rclone ];

        sops = {
          secrets = {
            r2-access-key-id.sopsFile = cfg.sopsFile;
            r2-secret-access-key.sopsFile = cfg.sopsFile;
          };

          templates."rclone-r2.conf".content = ''
            [r2]
            type = s3
            provider = Cloudflare
            access_key_id = ${config.sops.placeholder."r2-access-key-id"}
            secret_access_key = ${config.sops.placeholder."r2-secret-access-key"}
            endpoint = https://${cfg.accountId}.r2.cloudflarestorage.com
            region = auto
            no_check_bucket = true
          '';
        };

        systemd.user.services.rclone-r2 = {
          Unit = {
            Description = "Cloudflare R2 mount";
            After = [
              "graphical-session.target"
              "sops-nix.service"
            ];
            PartOf = [ "graphical-session.target" ];
            Requires = [ "sops-nix.service" ];
          };

          Service = {
            Type = "notify";
            ExecStartPre = "${lib.getExe' pkgs.coreutils "mkdir"} -p ${mountPoint} ${cacheDir}";
            ExecStart = ''
              ${lib.getExe pkgs.rclone} mount \
                r2:${cfg.bucket} \
                ${mountPoint} \
                --config ${config.sops.templates."rclone-r2.conf".path} \
                --cache-dir ${cacheDir} \
                --vfs-cache-mode writes
            '';
            Environment = [
              "PATH=/run/wrappers/bin:${lib.makeBinPath [ pkgs.fuse3 ]}"
            ];
            Restart = "on-failure";
            RestartSec = "10s";
          };

          Install.WantedBy = [ "graphical-session.target" ];
        };
      };
    };
}

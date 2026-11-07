{ config, ... }:

{
  my.programs.opencode.web = {
    enable = true;
    host = "100.91.91.87";
    environmentFile = config.sops.templates."opencode-web.env".path;
  };

  sops = {
    secrets.opencode-web-password = {
      sopsFile = ../../../secrets/opencode-web.yaml;
      key = "password";
    };
    templates."opencode-web.env" = {
      content = ''
        OPENCODE_SERVER_PASSWORD=${config.sops.placeholder.opencode-web-password}
      '';
      mode = "0400";
    };
  };

  systemd.user.services.opencode-web.Unit = {
    Requires = [ "sops-nix.service" ];
    After = [ "sops-nix.service" ];
  };
}

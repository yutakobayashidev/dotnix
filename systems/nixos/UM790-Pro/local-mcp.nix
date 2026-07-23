{
  config,
  inputs,
  lib,
  pkgs,
  username,
  ...
}:

let
  localMcpPkg = inputs.local-mcp.packages.${pkgs.stdenv.hostPlatform.system}.default;
  localMcp = pkgs.writeShellScriptBin "local-mcp" ''
    export XDG_STATE_HOME=''${XDG_STATE_HOME:-/var/lib/local-mcp}
    exec ${lib.getExe localMcpPkg} "$@"
  '';
  tunnelServiceName = "tunnel-client-local-mcp";
  tunnelCredentialName = "control-plane-api-key";
in
{
  imports = [ inputs.openai-secure-tunnel-nix.nixosModules.tunnel-client ];

  environment.systemPackages = [ localMcp ];

  sops.secrets.openai-tunnel-api-key = {
    sopsFile = ../../../secrets/openai-tunnel.yaml;
  };

  services.openai-tunnel-client.instances.local-mcp = {
    enable = true;
    user = username;
    group = "users";
    environment.XDG_STATE_HOME = "/var/lib/local-mcp";
    settings = {
      config_version = 1;
      control_plane = {
        tunnel_id = "tunnel_6a60d3a311408191adbde38bb2c77ee4";
        api_key = "file:/run/credentials/${tunnelServiceName}.service/${tunnelCredentialName}";
      };
      health.listen_addr = "127.0.0.1:18790";
      admin_ui.open_browser = false;
      mcp.commands = [
        {
          channel = "main";
          command = "${lib.getExe localMcpPkg} mcp";
        }
      ];
    };
    serviceConfig = {
      StateDirectory = "local-mcp";
      StateDirectoryMode = "0700";
      ProtectHome = "tmpfs";
      BindPaths = [ "/home/${username}/ghq" ];
    };
  };

  systemd.services.${tunnelServiceName}.serviceConfig.LoadCredential = [
    "${tunnelCredentialName}:${config.sops.secrets.openai-tunnel-api-key.path}"
  ];
}

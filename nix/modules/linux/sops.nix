{ ... }:
{
  sops = {
    defaultSopsFile = ../../../secrets/secrets.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets.wifi_env = {
      mode = "0400";
      restartUnits = [ "NetworkManager.service" ];
    };
  };
}

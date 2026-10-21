_:

let
  # B450M-Pro4's home LAN; keep discovery off Tailscale/container bridges.
  interface = "wlp2s0f0u5";
in
{
  services.matterjs-server = {
    enable = true;
    listenAddress = "127.0.0.1";
    bluetoothSupport = false;
    extraArgs = [ "--primary-interface=${interface}" ];
  };

  # Matter controllers use ephemeral UDP ports, not just 5540.
  # Accept IPv6 UDP on the trusted home LAN interface; retain TCP filtering.
  networking.firewall = {
    interfaces.${interface}.allowedUDPPorts = [ 5353 ];
    extraCommands = ''
      ip6tables -A nixos-fw -i ${interface} -p udp -j nixos-fw-accept
    '';
    extraStopCommands = ''
      ip6tables -D nixos-fw -i ${interface} -p udp -j nixos-fw-accept 2>/dev/null || true
    '';
  };
}

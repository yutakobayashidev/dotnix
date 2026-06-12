{ inputs, ... }:

let
  domain = "nostr.yutakobayashi.com";
  port = 3004;
in
{
  imports = [
    inputs.simple-nostr-relay.nixosModules.default
  ];

  services.simple-nostr-relay = {
    enable = true;
    inherit port;

    relayInformation = {
      name = domain;
      description = domain;
      pubkey = "2717dae5504081d0788597f387489b66f2950c4b49b263b797e87b496d1a26ce";
      contact = "mailto:hi@yutakobayashi.com";
    };
  };

  my.services.cloudflared-tunnel.ingress.${domain} = {
    service = "http://localhost:${toString port}";
  };
}

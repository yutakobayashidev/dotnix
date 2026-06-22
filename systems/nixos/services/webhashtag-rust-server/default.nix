{ inputs, ... }:

let
  domain = "tag.yutakobayashi.com";
  port = 3010;
in
{
  imports = [
    inputs.webhashtag-rust-server.nixosModules.default
  ];

  services.webhashtag-rust-server = {
    enable = true;
    tags = [
      "rust"
      "typescript"
    ];
    inherit port;
    listenAddress = "127.0.0.1";
    serverHost = domain;
    serverName = "WebHashtag Tag Server";
  };

  my.services.cloudflared-tunnel.ingress.${domain} = {
    service = "http://localhost:${toString port}";
  };
}

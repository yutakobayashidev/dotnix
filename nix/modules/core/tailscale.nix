# Tailscale設定
{ ... }:

{
  services.tailscale = {
    enable = true;
    extraUpFlags = [
      "--accept-dns=false"
      "--accept-routes"
    ];
  };
}

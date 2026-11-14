{
  services.kubo.enable = true;
  # UniFi devices use TCP 8080 to inform the controller.
  services.kubo.settings.Addresses.Gateway = "/ip4/127.0.0.1/tcp/18080";
}

_:

{
  services.matrix-continuwuity = {
    enable = true;
    settings = {
      global = {
        server_name = "example.com";

        # Continuwuity listens on localhost by default,
        # address and port are handled automatically.

        # You can add any further configuration here, e.g.
        # trusted_servers = [ "matrix.org" ];
      };
    };
  };
}

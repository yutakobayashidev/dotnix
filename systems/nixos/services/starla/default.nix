{ inputs, ... }:
{
  imports = [ inputs.starla.nixosModules.default ];

  services.starla = {
    enable = true;
    metrics.listenAddr = "127.0.0.1:9695";
  };

  services.victoriametrics.prometheusConfig.scrape_configs = [
    {
      job_name = "starla";
      static_configs = [
        { targets = [ "127.0.0.1:9695" ]; }
      ];
    }
  ];
}

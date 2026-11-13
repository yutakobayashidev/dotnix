_: {
  # Keep disabled until console access, isolated cabling, and rollback are reviewed.
  my.services.experimentalRouter = {
    enable = false;
    wanInterface = "wlp2s0";
    lanInterface = "enp1s0";
    subnetId = 10;
    upstreamDNS = "100.111.109.43";
  };
}

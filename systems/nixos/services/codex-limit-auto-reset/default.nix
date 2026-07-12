_:

{
  virtualisation.oci-containers.containers.codex-limit-auto-reset = {
    image = "ghcr.io/fa0311/codex-limit-auto-reset";
    volumes = [
      "/home/yuta/.config/codex:/data/codex"
    ];
  };
}

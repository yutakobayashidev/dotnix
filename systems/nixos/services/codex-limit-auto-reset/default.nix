_:

{
  virtualisation.oci-containers.containers.codex-limit-auto-reset = {
    image = "ghcr.io/fa0311/codex-limit-auto-reset:sha-a2f8db4@sha256:1ff5244ebc1fd0edd81892e9eaed0d9e3fa91b5c463d0ab1b47fd6c562c422a3";
    volumes = [
      "/home/yuta/.config/codex:/data/codex"
    ];
  };
}

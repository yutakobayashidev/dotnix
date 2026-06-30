{
  self,
  inputs,
  lib,
  pkgs,
  username,
  ...
}:

{
  # Base modules shared by regular NixOS hosts. Host-specific profiles still
  # decide whether the machine is desktop, server, or WSL.
  imports = [
    ../common.nix
    inputs.comin.nixosModules.comin
    inputs.sops-nix.nixosModules.sops
    inputs.nix-topology.nixosModules.default
    ../../modules/nixos
  ];

  nixpkgs = {
    overlays = [
      inputs.llm-agents.overlays.default
      (_final: _prev: {
        _tree-sitter-moonbit = inputs.tree-sitter-moonbit;
      })
      (
        _final: prev:
        let
          inherit (prev.stdenv.hostPlatform) system;
        in
        {
          bird = inputs.bird.packages.${system}.bird;
          discrawl = inputs.nix-openclaw-tools.packages.${system}.discrawl;
          edcb-tools = inputs.edcb-tools.packages.${system}.edcb-tools;
          ghostty = inputs.ghostty.packages.${system}.default;
          gogcli = inputs.nix-openclaw-tools.packages.${system}.gogcli;
          immich-go-no-docs = prev.symlinkJoin {
            name = "immich-go-no-docs";
            paths = [ prev.immich-go ];
            postBuild = ''
              rm -f $out/bin/docs
            '';
          };
          moonbit-lsp =
            let
              versions = import "${inputs.moonbit-overlay}/versions.nix" prev.lib;
              inherit (versions) latest;
              targets = {
                x86_64-linux = "linux-x86_64";
                aarch64-linux = "linux-aarch64";
                aarch64-darwin = "darwin-aarch64";
              };
              target = targets.${system} or null;
              hashAttr = if target != null then "${target}-toolchainsHash" else null;
            in
            if target != null && builtins.hasAttr hashAttr latest then
              prev.stdenv.mkDerivation {
                pname = "moonbit-lsp";
                inherit (latest) version;
                src = prev.fetchurl {
                  url = "https://github.com/moonbit-community/moonbit-overlay/releases/download/${prev.lib.escapeURL latest.version}/moonbit-${target}.tar.gz";
                  hash = latest.${hashAttr};
                };
                sourceRoot = ".";
                installPhase = ''
                  mkdir -p $out/bin
                  cp bin/moonbit-lsp $out/bin/moonbit-lsp
                  chmod +x $out/bin/moonbit-lsp
                '';
              }
            else
              null;
          repiq = inputs.repiq.packages.${system}.default.overrideAttrs (_: {
            doCheck = !prev.stdenv.hostPlatform.isDarwin;
          });
          version-lsp = inputs.version-lsp.packages.${system}.default;
        }
      )
      inputs.gh-nippou.overlays.default
      inputs.gh-graph.overlays.default
      inputs.rustowl-flake.overlays.default
      inputs.firefox-addons.overlays.default
      inputs.nix-cachyos-kernel.overlays.default
      inputs.nur-packages.overlays.default
      inputs.birdclaw.overlays.default
      inputs.nix-topology.overlays.default
    ]
    ++ lib.attrValues self.overlays;
  };

  sops = {
    defaultSopsFile = ../../secrets/default.yaml;
    age = {
      keyFile = "/home/${username}/.config/sops/age/keys.txt";
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      generateKey = true;
    };
  };

  nix.gc.dates = "weekly";

  nix.settings = {
    keep-outputs = true;
    keep-derivations = true;
    connect-timeout = 5;
    allowed-users = [ username ];
    trusted-users = [
      "root"
      username
    ];
  };

  # dhcpcd tries to manage Docker's veth interfaces and crashes (SEGV in ipv6nd_expire)
  # in a loop, which eventually causes DHCP lease renewal to fail after a few days
  networking.dhcpcd.denyInterfaces = [ "veth*" ];

  documentation.dev.enable = true;

  environment.systemPackages = with pkgs; [
    man-pages
    man-pages-ja
    man-pages-posix
  ];

  virtualisation.docker.enable = true;

  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
    # fix DNS issue caused by systemd-resolved
    # https://discourse.nixos.org/t/rootless-docker-systemd-resolved-and-dns-inside-containers/47030
    daemon.settings = {
      dns = [
        "1.1.1.1"
        "8.8.8.8"
      ];
    };
  };

  time.timeZone = "Asia/Tokyo";
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocales = [ "ja_JP.UTF-8/UTF-8" ];
  };

  users.users.${username} = {
    isNormalUser = true;
    description = username;
    shell = pkgs.zsh;
    linger = true;
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "adbusers"
    ];
    hashedPassword = "$6$jDoJHXil35EgTukO$t3Y3A9E37.q1MB7DTnud3YG8gpXS.QtXozfM95nG882i6slkmYHEtWrvdRK1iNiTrM2R.xzhbljbM31Uzc4XN1";
  };

  users.mutableUsers = false;

  programs = {
    zsh.enable = true;
    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        stdenv.cc.cc
      ];
    };
    ssh.startAgent = true;
  };

  services = {
    gnome.gcr-ssh-agent.enable = false;
    openssh.enable = true;
    pcscd.enable = true;
  };

  security.sudo.extraConfig = ''
    Defaults pwfeedback
  '';
}

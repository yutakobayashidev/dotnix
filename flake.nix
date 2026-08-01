{
  description = "yuta's NixOS & macOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-26.05";
    ax = {
      url = "github:yusukebe/ax";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-cachyos-kernel = {
      url = "github:xddxdd/nix-cachyos-kernel/release";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    comfyui-nix = {
      url = "github:utensils/comfyui-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    codex-desktop-linux = {
      url = "github:ilysenko/codex-desktop-linux";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nani-translate-linux = {
      url = "git+https://git.yutakobayashi.com/yuta/nani-translate-linux";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    microvm = {
      url = "github:astro/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    comin = {
      url = "github:nlewo/comin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niks3 = {
      url = "github:Mic92/niks3";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.treefmt-nix.follows = "treefmt-nix";
    };
    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
      inputs.flake-parts.follows = "flake-parts";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ghostty.url = "github:ghostty-org/ghostty";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri-flake = {
      url = "github:sodiboo/niri-flake";
      inputs = {
        niri-stable.follows = "";
        niri-unstable.follows = "";
        nixpkgs-stable.follows = "nixpkgs-stable";
        nixpkgs.follows = "nixpkgs";
        xwayland-satellite-stable.follows = "";
        xwayland-satellite-unstable.follows = "";
      };
    };
    vicinae-extensions = {
      url = "github:vicinaehq/extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote?rev=2a9c6ba61f2e1bd6eaf4e1e12aca77699bf7ea95";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    llm-agents.url = "github:numtide/llm-agents.nix";
    local-mcp = {
      url = "github:nakasyou/local-mcp";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-openclaw-tools = {
      url = "github:openclaw/nix-openclaw-tools";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    openclaw = {
      url = "github:openclaw/openclaw";
      flake = false;
    };
    gh-nippou = {
      url = "github:ryoppippi/gh-nippou";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    gh-graph = {
      url = "github:kawarimidoll/gh-graph";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-hazkey = {
      url = "github:aster-void/nix-hazkey";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agent-skills = {
      url = "github:Kyure-A/agent-skills-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agent-scripts = {
      url = "github:steipete/agent-scripts";
      flake = false;
    };
    superpowers = {
      url = "github:obra/superpowers";
      flake = false;
    };
    anthropic-skills = {
      url = "github:anthropics/skills";
      flake = false;
    };
    ast-grep-skill = {
      url = "github:ast-grep/claude-skill";
      flake = false;
    };
    obsidian-skills = {
      url = "github:kepano/obsidian-skills";
      flake = false;
    };
    oracle-skill = {
      url = "github:yutakobayashidev/oracle";
      flake = false;
    };
    prompt-review-skill = {
      url = "github:tokoroten/prompt-review";
      flake = false;
    };
    difit-skills = {
      url = "github:yoshiko-pg/difit";
      flake = false;
    };
    droidperm = {
      url = "github:yutakobayashidev/droidperm";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agent-browser-skill = {
      url = "github:vercel-labs/agent-browser";
      flake = false;
    };
    before-and-after-skill = {
      url = "github:vercel-labs/before-and-after";
      flake = false;
    };
    mattpocock-skills = {
      url = "github:mattpocock/skills";
      flake = false;
    };
    i-have-adhd-skill = {
      url = "github:ayghri/i-have-adhd";
      flake = false;
    };
    twitter-api-safe-relay-skills = {
      url = "github:fa0311/twitter_api_safe_relay_skills";
      flake = false;
    };
    hashicorp-agent-skills = {
      url = "github:hashicorp/agent-skills";
      flake = false;
    };
    herdr-skill = {
      url = "github:ogulcancelik/herdr";
      flake = false;
    };
    skills = {
      url = "github:yutakobayashidev/skills";
      flake = false;
    };
    repiq = {
      url = "github:yutakobayashidev/repiq";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    temari = {
      url = "github:yutakobayashidev/temari";
      inputs.agent-skills-nix.follows = "agent-skills";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur-packages = {
      url = "github:yutakobayashidev/nur-packages";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    openai-secure-tunnel-nix = {
      url = "github:nakasyou/openai-secure-tunnel-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    openbrief = {
      url = "github:yutakobayashidev/open-brief";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    starla = {
      url = "github:ananthb/starla/v0.3.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    simple-nostr-relay.url = "github:yutakobayashidev/simple-nostr-relay";
    webhashtag-rust-server = {
      url = "github:yutakobayashidev/webhashtag-rust-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    onepassword-shell-plugins.url = "github:1Password/shell-plugins";
    brew-nix = {
      url = "github:BatteredBunny/brew-nix";
      inputs = {
        brew-api.follows = "brew-api";
        nix-darwin.follows = "nix-darwin";
        nixpkgs.follows = "nixpkgs";
      };
    };
    brew-api = {
      url = "github:BatteredBunny/brew-api";
      flake = false;
    };
    bird = {
      url = "git+https://git.yutakobayashi.com/yuta/bird";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    twitter-lite = {
      url = "git+https://git.yutakobayashi.com/yuta/twitter-lite";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    birdclaw = {
      url = "github:yutakobayashidev/birdclaw";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    edcb-tools = {
      url = "github:yutakobayashidev/edcb-tools";
      inputs.fenix.follows = "webhashtag-rust-server/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mcp-servers-nix = {
      url = "github:natsukium/mcp-servers-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-on-droid = {
      url = "github:nix-community/nix-on-droid";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rustowl-flake = {
      url = "github:nix-community/rustowl-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    version-lsp = {
      url = "github:skanehira/version-lsp";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    moonbit-overlay = {
      url = "github:moonbit-community/moonbit-overlay";
      flake = false;
    };
    nix-topology = {
      url = "github:oddlama/nix-topology";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixtopsy.url = "github:amaanq/nixtopsy";
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
      "https://cache.numtide.com"
      "https://nix-cache.yutakobayashi.com"
      "https://yuta.cachix.org"
      "https://devenv.cachix.org"
      "https://nix-community.cachix.org"
      "https://vicinae.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "niks3-1:Ay1+L/bEpRLOvfcAspotbB8TgNHIkMF1gX28uUcYwhM="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "yuta.cachix.org-1:VGiC7m0kQjut7lp+RG/9pCRHFpzf11ELQrM2Nc2QCCk="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
    ];
  };

  outputs =
    { flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      imports = [
        ./flake-module.nix
        ./modules
        inputs.nix-topology.flakeModule
      ];

      flake = {
        overlays = import ./overlays { inherit inputs; };
      };

      hosts = {
        installer = {
          system = "x86_64-linux";
        };
        B450M-Pro4 = {
          system = "x86_64-linux";
        };
        UM790-Pro = {
          system = "x86_64-linux";
        };
        ThinkPad-X1-Carbon-Gen13 = {
          system = "x86_64-linux";
        };
        X870-Steel-Legend-WiFi = {
          system = "x86_64-linux";
        };
        X870-Steel-Legend-WiFi-WSL = {
          system = "x86_64-linux";
        };
        pi5 = {
          system = "aarch64-linux";
        };
        oci-a1 = {
          system = "aarch64-linux";
        };
        M2-MacBook-Air = {
          system = "aarch64-darwin";
        };
        Galaxy-S23FE = {
          system = "aarch64-linux";
          platform = "android";
        };
      };
    };
}

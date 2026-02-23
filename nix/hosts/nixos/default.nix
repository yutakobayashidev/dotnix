{ inputs }:
let
  inherit (inputs)
    nixpkgs
    home-manager
    niri
    nix-hazkey
    nix-filter
    moonbit-overlay
    ;

  system = "x86_64-linux";

  helpers = import ../../modules/lib/helpers { lib = nixpkgs.lib; };
  dotfilesDir = "/home/yuta/ghq/github.com/yutakobayashidev/dotnix";
  customOverlay = import ../../overlays;

  local-skills = nix-filter.lib {
    root = inputs.self;
    include = [ "agents/skills" ];
  };

  externalOverlay = final: prev: {
    claude-code = inputs.llm-agents.packages.${system}.claude-code;
    ccusage = inputs.llm-agents.packages.${system}.ccusage;
    codex = inputs.llm-agents.packages.${system}.codex;
    opencode = inputs.llm-agents.packages.${system}.opencode;
    vibe-kanban = inputs.llm-agents.packages.${system}.vibe-kanban;
    cursor-agent = inputs.llm-agents.packages.${system}.cursor-agent;
    gogcli = inputs.nix-steipete-tools.packages.${system}.gogcli;
    version-lsp = inputs.version-lsp.packages.${system}.default.overrideAttrs (oldAttrs: {
      doCheck = false;
    });
    gh-nippou = inputs.gh-nippou.packages.${system}.default;
    gh-graph = inputs.gh-graph.packages.${system}.default;
    ghostty = inputs.ghostty.packages.${system}.default;
  };
in
nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = {
    inherit
      helpers
      dotfilesDir
      home-manager
      niri
      local-skills
      ;
    inherit (inputs)
      anthropic-skills
      vercel-skills
      ui-ux-pro-max-skill
      ast-grep-skill
      cloudflare-skills
      hashicorp-agent-skills
      deno-skills
      aws-agent-skills
      agent-skills
      mcp-servers-nix
      ;
  };
  modules = [
    ../../modules/linux
    ./configuration.nix
    ../../profiles/gui.nix
    {
      nixpkgs.overlays = [
        externalOverlay
        moonbit-overlay.overlays.default
        customOverlay
      ];
      nixpkgs.config.allowUnfreePredicate =
        pkg:
        builtins.elem (nixpkgs.lib.getName pkg) [
          "claude-code"
          "android-studio"
          "google-chrome"
          "discord"
          "slack"
          "obsidian"
          "1password"
          "insomnia"
          "spotify"
        ];
    }
    nix-hazkey.nixosModules.hazkey
  ];
}

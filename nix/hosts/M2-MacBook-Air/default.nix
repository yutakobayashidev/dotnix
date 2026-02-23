{ inputs }:
let
  inherit (inputs)
    nixpkgs
    nix-darwin
    home-manager
    nix-filter
    moonbit-overlay
    brew-nix
    ;

  system = "aarch64-darwin";

  helpers = import ../../modules/lib/helpers { lib = nixpkgs.lib; };
  dotfilesDir = "/Users/yuta/ghq/github.com/yutakobayashidev/dotnix";
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
  };
in
nix-darwin.lib.darwinSystem {
  inherit system;
  specialArgs = {
    inherit inputs;
  };
  modules = [
    ../../modules/darwin
    ./configuration.nix
    ../../profiles/darwin.nix
    {
      nixpkgs.overlays = [
        externalOverlay
        moonbit-overlay.overlays.default
        customOverlay
        brew-nix.overlays.default
      ];
      nixpkgs.config.allowUnfree = true;
    }
    {
      imports = [ home-manager.darwinModules.home-manager ];

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        extraSpecialArgs = {
          inherit
            inputs
            helpers
            dotfilesDir
            local-skills
            ;
        };
        sharedModules = [ inputs.agent-skills.homeManagerModules.default ];
        users.yuta =
          { pkgs, ... }:
          {
            imports = [
              ../../modules/home
              inputs.onepassword-shell-plugins.hmModules.default
            ];
            home.homeDirectory = "/Users/yuta";
            programs.onepassword-shell-plugins = {
              enable = true;
              plugins = with pkgs; [
                gh
                awscli2
              ];
            };
          };
      };

      users.users.yuta.home = "/Users/yuta";

      nix.settings.trusted-users = [
        "root"
        "yuta"
      ];
    }
  ];
}

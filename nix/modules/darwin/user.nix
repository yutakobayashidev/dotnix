{ pkgs, home-manager, helpers, dotfilesDir, local-skills, anthropic-skills, vercel-skills, ui-ux-pro-max-skill, agent-skills, onepassword-shell-plugins, ... }:

{
  imports = [ home-manager.darwinModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit helpers dotfilesDir local-skills anthropic-skills vercel-skills ui-ux-pro-max-skill onepassword-shell-plugins;
    };
    sharedModules = [ agent-skills.homeManagerModules.default ];
    users.yuta = import ../home/darwin.nix;
  };

  users.users.yuta.home = "/Users/yuta";

  nix.settings.trusted-users = [
    "root"
    "yuta"
  ];
}

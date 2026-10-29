# Evaluate with the actual Home Manager module graph, not a mock module harness.
{ configuration }:
let
  inherit (configuration) config;
  inherit (configuration.pkgs) lib;
  packageNames = map lib.getName config.home.packages;
in
assert config.home.username == "box";
assert config.home.homeDirectory == "/home/box";
assert config.my.profiles.base.enable && config.my.profiles.development.enable;
assert !config.my.profiles.desktop.enable;
assert config.home.profileDirectory == "/home/box/.nix-profile";
assert config.nix.settings.build-users-group == "";
assert builtins.elem "flakes" config.nix.settings.experimental-features;
assert !config.systemd.user.enable;
assert config.systemd.user.services == { };
assert config.sops.secrets == { };
assert !config.my.programs.codex.desktopIntegration;
assert !config.my.programs.codex.telemetry.enable;
assert !config.my.programs.claude-code.telemetry.enable;
assert !config.programs.atuin.settings.auto_sync;
assert builtins.all (file: !(file.enable && lib.hasSuffix "/codex/hooks.json" file.target)) (
  builtins.attrValues config.home.file
);
assert builtins.all (name: builtins.elem name packageNames) [
  "git"
  "jq"
  "ripgrep"
  "zsh"
];
assert !(builtins.elem "session-tts" packageNames);
true

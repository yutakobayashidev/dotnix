{
  flake.templates.diy = {
    path = ../../templates/diy;
    description = "Composable firmware, CAD, PCB and 3D printing environments";
    welcomeText = ''
      Run `nix develop` for firmware tools; on Linux, use `nix develop .#full` for all tools.
      See README.md for profiles, project-local agent skills, and device access.
    '';
  };
  flake.templates.mobile = {
    path = ../../templates/mobile;
    description = "Linux Android development and APK analysis with coding agents";
    welcomeText = ''
      Run `nix develop`, then `mobile doctor`.
      See README.md for SDK licensing, KVM setup, and the analysis shell.
    '';
  };
}

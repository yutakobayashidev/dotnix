{ lib, pkgs, ... }:

{
  environment.variables = {
    BIRD_PROFILE_NAME = "account1";
    EDCB_HOST = "100.111.109.43";
    EDCB_PORT = "4510";
    EDCB_TIMEOUT_SECONDS = "15";
  };

  system.activationScripts.extraActivation.text = ''
    profiles=$(find /nix/var/nix/profiles/system-*-link 2>/dev/null | tail -2)
    profile_count=$(echo "$profiles" | wc -l)
    if [ "$profile_count" -ge 2 ]; then
      # shellcheck disable=SC2086
      ${lib.getExe pkgs.nix} --extra-experimental-features 'nix-command flakes' store diff-closures $profiles
    else
      echo "No previous generation to compare with."
    fi
  '';
}

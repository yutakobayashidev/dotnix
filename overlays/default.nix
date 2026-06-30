_:

let
  overlayFiles = [
    ./dev-tools.nix
    ./session-tts-codex.nix
    ./speechrecognition.nix
    ./tree-sitter-moonbit.nix
  ];

  local = builtins.foldl' (
    acc: overlay: final: prev:
    (acc final prev) // ((import overlay) final prev)
  ) (_: _: { }) overlayFiles;
in
{
  inherit local;

  patches = final: prev: {
    gh = final.writeShellApplication {
      name = "gh";
      text = ''
        if [ -z "''${GH_TOKEN:-}" ] && [ -z "''${GITHUB_TOKEN:-}" ]; then
          GH_TOKEN="$(${final.lib.getExe final.ghtkn} get)"
          export GH_TOKEN
        fi

        exec ${final.lib.getExe prev.gh} "$@"
      '';
    };
  };
}

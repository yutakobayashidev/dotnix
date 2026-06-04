let
  overlayFiles = [
    ./dev-tools.nix
    ./session-tts-codex.nix
    ./speechrecognition.nix
    ./tree-sitter-moonbit.nix
  ];
in
builtins.foldl' (
  acc: overlay: final: prev:
  (acc final prev) // ((import overlay) final prev)
) (_: _: { }) overlayFiles

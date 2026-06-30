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
}

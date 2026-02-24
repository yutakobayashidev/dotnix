let
  overlayFiles = [
    ./ai-tools.nix
    ./dev-tools.nix
    ./difit.nix
    ./jj-desc.nix
    ./keifu.nix
    ./polycat.nix
    ./pretty-ts-errors-markdown.nix
    ./similarity-ts.nix
    ./tunnelto.nix
  ];
in
builtins.foldl' (
  acc: overlay: final: prev:
  (acc final prev) // ((import overlay) final prev)
) (_: _: { }) overlayFiles

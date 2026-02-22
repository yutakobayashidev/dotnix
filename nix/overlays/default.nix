let
  overlayFiles = [
    ./aqua.nix
    ./difit.nix
    ./entire.nix
    ./jj-desc.nix
    ./keifu.nix
    ./polycat.nix
    ./pretty-ts-errors-markdown.nix
    ./similarity-ts.nix
  ];
in
builtins.foldl' (
  acc: overlay: final: prev:
  (acc final prev) // ((import overlay) final prev)
) (_: _: { }) overlayFiles

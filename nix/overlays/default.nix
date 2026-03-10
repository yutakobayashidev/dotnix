let
  overlayFiles = [
    ./ai-tools.nix
    ./bit-vcs.nix
    ./continues.nix
    ./dev-tools.nix
    ./difit.nix
    ./jj-desc.nix
    ./keifu.nix
    ./opensrc.nix
    ./polycat.nix
    ./pretty-ts-errors-markdown.nix
    ./readout.nix
    ./similarity-ts.nix
    ./tree-sitter-moonbit.nix
    ./tunnelto.nix
  ];
in
builtins.foldl' (
  acc: overlay: final: prev:
  (acc final prev) // ((import overlay) final prev)
) (_: _: { }) overlayFiles

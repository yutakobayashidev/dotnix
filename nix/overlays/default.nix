final: prev:
let
  sources = import ./_sources/generated.nix {
    inherit (final)
      fetchgit
      fetchurl
      fetchFromGitHub
      dockerTools
      ;
  };

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
  acc: overlay: acc // ((import overlay) { inherit sources final prev; })
) { } overlayFiles

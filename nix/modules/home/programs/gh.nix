{ pkgs, ... }:

{
  home.packages = with pkgs; [
    gh
    # gh-nippou  # temporarily disabled due to hash mismatch
    ghq
    tea
  ];
}

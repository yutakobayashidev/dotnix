{ ... }:
{
  mkLinkForce = ''
    link_force() {
      local src=$1
      local dst=$2
      $DRY_RUN_CMD rm -rf "$dst"
      $DRY_RUN_CMD ln -sf "$src" "$dst"
    }
  '';
}

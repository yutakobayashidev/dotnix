{ lib, isDarwin }:
{
  default = [ "firmware" ];
  electronics = [
    "firmware"
    "arduino-ide"
  ];
  cad = [ "cad" ];
  printing = [ "printing" ];
  # Example: enclosure = [ "firmware" "cad" ];
}
// lib.optionalAttrs (!isDarwin) {
  # The pinned Nixpkgs KiCad package is marked broken on Darwin.
  pcb = [ "pcb" ];
  full = [
    "firmware"
    "arduino-ide"
    "cad"
    "pcb"
    "printing"
  ];
}

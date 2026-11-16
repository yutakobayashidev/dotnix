{
  pkgs,
  stable,
  casks,
  skills,
}:
{
  features,
  extraPackages ? [ ],
}:
let
  inherit (pkgs) lib;
  darwin = pkgs.stdenv.hostPlatform.isDarwin;
  # Nixpkgs' Linux wrappers provide an FHS environment for downloaded toolchains.
  firmware = [
    pkgs.arduino-cli
    (if darwin then pkgs.platformio-core else pkgs.platformio)
  ];
  arduinoIDE = if darwin then casks.arduino-ide else pkgs.arduino-ide;
  freecad = if darwin then casks.freecad else stable.freecad;
  # Cask applications are not linked into /Applications by a dev shell.
  launchApp =
    name: package: app:
    pkgs.writeShellScriptBin name ''
      exec /usr/bin/open -a ${lib.escapeShellArg "${package}/Applications/${app}"} --args "$@"
    '';
  groups = {
    inherit firmware;
    arduino-ide = [
      arduinoIDE
    ]
    ++ lib.optional darwin (launchApp "diy-arduino-ide" arduinoIDE "Arduino IDE.app");
    cad = [
      freecad
      pkgs.openscad
    ]
    ++ lib.optional darwin (launchApp "diy-freecad" freecad "FreeCAD.app");
    pcb = [ (pkgs.kicad.override { stable = true; }) ];
    printing =
      if darwin then
        [
          casks.prusaslicer
          (launchApp "diy-prusa-slicer" casks.prusaslicer "Original Prusa Drivers/PrusaSlicer.app")
        ]
      else
        [ pkgs.prusa-slicer ];
  };
  unknown = lib.subtractLists (builtins.attrNames groups) features;
in
assert lib.assertMsg (unknown == [ ]) "Unknown DIY features: ${lib.concatStringsSep ", " unknown}";
pkgs.mkShellNoCC {
  packages = [
    pkgs.git
  ]
  ++ lib.unique (lib.concatMap (name: groups.${name}) features)
  ++ extraPackages;
  shellHook = ''
    export DIY_WORKSPACE="$PWD"
    export ARDUINO_DIRECTORIES_DATA="$DIY_WORKSPACE/.diy/arduino/data"
    export ARDUINO_DIRECTORIES_DOWNLOADS="$DIY_WORKSPACE/.diy/arduino/downloads"
    export ARDUINO_DIRECTORIES_USER="$DIY_WORKSPACE/firmware/arduino"
    export PLATFORMIO_CORE_DIR="$DIY_WORKSPACE/.diy/platformio"
    mkdir -p "$ARDUINO_DIRECTORIES_DATA" "$ARDUINO_DIRECTORIES_DOWNLOADS" "$PLATFORMIO_CORE_DIR"
    ${skills.shellHook}
  '';
}

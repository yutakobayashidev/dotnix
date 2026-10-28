{ lib }:
let
  roomModule =
    (import ../modules/features/observability/room-alerts.nix { }).flake.modules.nixos.room-alerts;
  evaluated = lib.evalModules {
    modules = [
      roomModule
      {
        options = {
          services = lib.mkOption {
            type = lib.types.attrs;
            default = { };
          };
          networking.hostName = lib.mkOption { type = lib.types.str; };
          assertions = lib.mkOption {
            type = lib.types.listOf lib.types.attrs;
            default = [ ];
          };
        };
        config = {
          networking.hostName = "test-host";
          my.services.roomAlerts = {
            enable = true;
            sensors = {
              "sensor.indoor_temperature" = {
                kind = "temperature";
                name = "Indoor temperature";
              };
              "binary_sensor.front_door" = {
                kind = "door-open";
                name = "Front door";
              };
              "lock.front_door" = {
                kind = "unlocked";
                name = "Front door lock";
              };
            };
          };
        };
      }
    ];
  };
in
assert lib.all (a: a.assertion) evaluated.config.assertions;
evaluated.config.services.vmalert.instances.main.rules

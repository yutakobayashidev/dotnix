_: {
  flake.modules.nixos.room-alerts =
    { config, lib, ... }:
    let
      cfg = config.my.services.roomAlerts;
      defaults = {
        temperature = {
          metric = "homeassistant_sensor_temperature_celsius";
          low = 10;
          high = 30;
          duration = "30m";
          unit = "°C";
        };
        humidity = {
          metric = "homeassistant_sensor_humidity_percent";
          low = 40;
          high = 65;
          duration = "1h";
          unit = "%";
        };
        co2 = {
          metric = "homeassistant_sensor_carbon_dioxide_ppm";
          low = null;
          high = 1500;
          duration = "15m";
          unit = "ppm";
        };
        pm25 = {
          metric = "homeassistant_sensor_pm25_u0xb5g_per_mu0xb3";
          low = null;
          high = 10;
          duration = "3m";
          unit = "µg/m³";
        };
        door-open = {
          metric = "homeassistant_binary_sensor_state";
          low = null;
          high = null;
          equals = 1;
          duration = "10m";
          unit = "";
        };
        unlocked = {
          metric = "homeassistant_lock_state";
          low = null;
          high = null;
          equals = 0;
          duration = "30m";
          unit = "";
        };
        state = {
          metric = "homeassistant_sensor_state";
          low = null;
          high = null;
          duration = "1m";
          unit = "";
        };
        battery = {
          metric = "homeassistant_sensor_battery_percent";
          low = 20;
          high = null;
          duration = "1h";
          unit = "%";
        };
      };
      sensorRules =
        entity: sensor:
        let
          unitSuffix = lib.optionalString (sensor.unit != "") " ${sensor.unit}";
          selector = ''${sensor.metric}{job="home-assistant",entity=${builtins.toJSON entity}}'';
          unavailable = ''homeassistant_entity_available{job="home-assistant",entity=${builtins.toJSON entity}} == 0'';
          labels = {
            category = "room";
            inherit entity;
            host = config.networking.hostName;
            severity = if sensor.kind == "battery" then "info" else "warning";
          };
          threshold = suffix: operator: value: {
            alert = "RoomSensor${suffix}";
            expr = "(${selector} ${operator} ${toString value}) unless on(job, entity) (${unavailable})";
            for = sensor.duration;
            inherit labels;
            annotations = {
              summary = "${sensor.name}: ${sensor.kind} ${lib.toLower suffix}";
              description = ''Current value {{ printf "%.1f" $value }}${unitSuffix}; threshold ${operator} ${toString value}${unitSuffix} for ${sensor.duration}.'';
            };
          };
        in
        lib.optional (sensor.low != null) (threshold "Low" sensor.lowOperator sensor.low)
        ++ lib.optional (sensor.high != null) (threshold "High" sensor.highOperator sensor.high)
        ++ lib.optional (sensor.equals != null) (threshold "State" "==" sensor.equals)
        ++ [
          {
            alert = "RoomSensorUnavailable";
            expr = ''(absent_over_time(${selector}[15m]) or on(job, entity) (max by (job, entity) (${unavailable}))) and on() (up{job="home-assistant"} == 1)'';
            for = "5m";
            labels = labels // {
              severity = "warning";
            };
            annotations.summary = "${sensor.name}: sensor data unavailable";
            annotations.description = "Home Assistant responds, but ${entity} is unavailable or has exported no ${sensor.metric} samples for at least 15 minutes.";
          }
        ];
    in
    {
      options.my.services.roomAlerts = {
        enable = lib.mkEnableOption "Home Assistant room and sensor alerts";
        sensors = lib.mkOption {
          default = { };
          description = "Explicit indoor sensor entity IDs; add only entities confirmed in the HA metrics endpoint.";
          type = lib.types.attrsOf (
            lib.types.submodule (
              { name, config, ... }: {
                options = {
                  kind = lib.mkOption {
                    type = lib.types.enum [
                      "temperature"
                      "humidity"
                      "co2"
                      "battery"
                      "pm25"
                      "door-open"
                      "unlocked"
                      "state"
                    ];
                  };
                  name = lib.mkOption {
                    type = lib.types.str;
                    default = name;
                    description = "Human-readable sensor name.";
                  };
                  metric = lib.mkOption {
                    type = lib.types.strMatching "[a-zA-Z_:][a-zA-Z0-9_:]*";
                    default = defaults.${config.kind}.metric;
                  };
                  low = lib.mkOption {
                    type = lib.types.nullOr lib.types.number;
                    default = defaults.${config.kind}.low;
                  };
                  high = lib.mkOption {
                    type = lib.types.nullOr lib.types.number;
                    default = defaults.${config.kind}.high;
                  };
                  equals = lib.mkOption {
                    type = lib.types.nullOr lib.types.number;
                    default = defaults.${config.kind}.equals or null;
                    description = "Exact state value which triggers a sustained-state alert.";
                  };
                  lowOperator = lib.mkOption {
                    type = lib.types.enum [
                      "<"
                      "<="
                    ];
                    default = "<";
                  };
                  highOperator = lib.mkOption {
                    type = lib.types.enum [
                      ">"
                      ">="
                    ];
                    default = if config.kind == "state" then ">=" else ">";
                  };
                  duration = lib.mkOption {
                    type = lib.types.strMatching "[0-9]+[smhdw]";
                    default = defaults.${config.kind}.duration;
                  };
                  unit = lib.mkOption {
                    type = lib.types.str;
                    default = defaults.${config.kind}.unit;
                  };
                };
              }
            )
          );
        };
      };
      config = lib.mkIf cfg.enable {
        assertions = lib.mapAttrsToList (entity: sensor: {
          assertion = sensor.low != null || sensor.high != null || sensor.equals != null;
          message = "Room sensor ${entity} needs at least one low, high, or equals threshold.";
        }) cfg.sensors;
        services.vmalert.instances.main.rules.groups = [
          {
            name = "room";
            rules = [
              {
                alert = "HomeAssistantMetricsUnavailable";
                expr = ''up{job="home-assistant"} == 0 or absent(up{job="home-assistant"})'';
                for = "5m";
                labels = {
                  category = "room";
                  severity = "warning";
                  host = config.networking.hostName;
                };
                annotations.summary = "Home Assistant metrics unavailable";
                annotations.description = "Room alerts cannot evaluate current sensor values. Check Home Assistant, its metrics token, and the scrape configuration.";
              }
            ]
            ++ lib.concatLists (lib.mapAttrsToList sensorRules cfg.sensors);
          }
        ];
      };
    };
}

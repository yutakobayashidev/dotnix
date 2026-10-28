_: {
  flake.modules.nixos.monitoring =
    {
      config,
      inputs,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.services.monitoring;
      machines = inputs.self.nixosConfigurations // inputs.self.darwinConfigurations;
      targets = lib.mapAttrsToList (name: machine: {
        targets = [
          "${
            if name == config.networking.hostName then "127.0.0.1" else name
          }:${toString machine.config.services.prometheus.exporters.node.port}"
        ];
        labels = {
          host = name;
          always_on = if builtins.elem name cfg.alwaysOnHosts then "true" else "false";
          role =
            if
              builtins.elem name [
                "UM790-Pro"
                "M2-MacBook-Air"
              ]
            then
              "builders"
            else if builtins.elem name cfg.alwaysOnHosts then
              "servers"
            else
              "clients";
        };
      }) (lib.filterAttrs (name: _: builtins.elem name cfg.nodeHosts) machines);
      # APFS slices and Btrfs subvolumes share capacity; alert once per pool.
      filesystemFree =
        selector:
        let
          free = "100 * node_filesystem_avail_bytes{${selector}} / node_filesystem_size_bytes";
        in
        ''min by(host, instance, pool) (label_replace(label_replace(${free}, "pool", "$1", "device", "(.*)"), "pool", "$1", "device", "(/dev/disk[0-9]+)s[0-9]+.*"))'';
      rule = alert: expr: duration: severity: summary: {
        inherit alert expr;
        for = duration;
        labels = {
          inherit severity;
          category = "infra";
        };
        annotations = { inherit summary; };
      };
      yaml = pkgs.formats.yaml { };
    in
    {
      options.my.services.monitoring = {
        enable = lib.mkEnableOption "central VictoriaMetrics monitoring and vmalert";
        alwaysOnHosts = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            "B450M-Pro4"
            "UM790-Pro"
            "pi5"
          ];
          description = "Hosts whose absence is an outage; builders and laptops may be offline.";
        };
        nodeHosts = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            "B450M-Pro4"
            "pi5"
            "UM790-Pro"
            "M2-MacBook-Air"
            "ThinkPad-X1-Carbon-Gen13"
            "X870-Steel-Legend-WiFi"
          ];
          description = "Hosts whose node exporter is collected.";
        };
      };
      config = lib.mkIf cfg.enable {
        services.victoriametrics = {
          enable = true;
          listenAddress = "127.0.0.1:8428";
          retentionPeriod = "1y";
          # HA bearer credentials exist only at runtime.
          checkConfig = false;
          extraOptions = [
            "-search.maxLookback=5m"
            "-vmalert.proxyURL=http://127.0.0.1:8880"
          ];
          prometheusConfig = {
            global.scrape_interval = "1m";
            scrape_configs = [
              {
                job_name = "node";
                static_configs = targets;
              }
              {
                job_name = "monitoring";
                static_configs = [
                  {
                    targets = [
                      "127.0.0.1:8428"
                      "127.0.0.1:8880"
                    ];
                    labels.host = config.networking.hostName;
                  }
                ];
              }
            ];
          };
        };
        services.vmalert.instances.main = {
          enable = true;
          settings = {
            "datasource.url" = "http://127.0.0.1:8428";
            "httpListenAddr" = "127.0.0.1:8880";
            "remoteWrite.url" = "http://127.0.0.1:8428";
            "remoteRead.url" = "http://127.0.0.1:8428";
            disableAlertgroupLabel = true;
          };
          rules.groups = [
            {
              name = "infra";
              rules = [
                (rule "InstanceDown" ''up{job="node",always_on="true"} == 0'' "5m" "critical"
                  "{{ $labels.host }} is unreachable"
                )
                (rule "SystemdUnitFailed" ''node_systemd_unit_state{state="failed"} == 1'' "5m" "warning"
                  "{{ $labels.host }}: {{ $labels.name }} failed"
                )
                (rule "FilesystemSpaceLow"
                  "${filesystemFree ''fstype!~"tmpfs|ramfs|overlay",mountpoint!~"/boot.*"''} < 15"
                  "30m"
                  "warning"
                  "{{ $labels.host }} {{ $labels.pool }}: less than 15% free"
                )
                (rule "FilesystemSpaceLow" "${filesystemFree ''fstype!~"tmpfs|ramfs|overlay"''} < 5" "10m"
                  "critical"
                  "{{ $labels.host }} {{ $labels.pool }}: less than 5% free"
                )
                (rule "MemoryPressureHigh"
                  "(100 * (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) or 100 * ((node_memory_active_bytes + node_memory_wired_bytes + node_memory_compressed_bytes) / node_memory_total_bytes)) > 90"
                  "30m"
                  "warning"
                  "{{ $labels.host }} memory above 90%"
                )
                (rule "OOMKillDetected" "increase(node_vmstat_oom_kill[10m]) > 0" "0m" "warning"
                  "{{ $labels.host }} OOM killer active"
                )
                (rule "MonitoringTargetDown" ''up{job="monitoring"} == 0'' "5m" "critical"
                  "Monitoring component {{ $labels.instance }} is unreachable"
                )
                (rule "MetricsConfigReloadFailed" "vm_promscrape_config_last_reload_successful == 0" "5m" "critical"
                  "VictoriaMetrics scrape configuration reload failed"
                )
                (rule "AlertRuleEvaluationFailing" "increase(vmalert_execution_errors_total[15m]) > 0" "5m"
                  "warning"
                  "vmalert rule evaluation failed"
                )
                (rule "AlertNotificationFailing" "increase(vmalert_alerts_send_errors_total[15m]) > 0" "5m"
                  "critical"
                  "vmalert cannot deliver alerts"
                )
              ];
            }
          ];
        };
        environment.etc."alloy/infrastructure.alloy".text = ''
          loki.relabel "infrastructure" {
            forward_to = [loki.write.default.receiver]
            rule {
              source_labels = ["__journal__systemd_unit"]
              target_label = "unit"
            }
            rule {
              source_labels = ["__journal_priority_keyword"]
              target_label = "level"
            }
          }
          loki.source.journal "infrastructure" {
            forward_to = [loki.relabel.infrastructure.receiver]
            matches = "_SYSTEMD_UNIT=traefik.service + _SYSTEMD_UNIT=home-assistant.service + _SYSTEMD_UNIT=gitea.service + _SYSTEMD_UNIT=victoriametrics.service + _SYSTEMD_UNIT=vmalert-main.service + _SYSTEMD_UNIT=alertmanager.service + _SYSTEMD_UNIT=opentelemetry-collector.service + _SYSTEMD_UNIT=tempo.service"
            labels = { job = "infrastructure", host = "${config.networking.hostName}" }
          }
        '';
        systemd.services.vmalert-main = {
          after = [ "victoriametrics.service" ];
          wants = [ "victoriametrics.service" ];
        };
        system.checks = [
          (pkgs.runCommand "monitoring-alloy-config-check" { } ''
            ${lib.getExe pkgs.grafana-alloy} validate ${
              pkgs.writeText "alloy.alloy" (
                lib.concatStringsSep "\n" (
                  lib.mapAttrsToList (_: value: value.text) (
                    lib.filterAttrs (
                      name: value: lib.hasPrefix "alloy/" name && value.text != null
                    ) config.environment.etc
                  )
                )
              )
            }
            touch $out
          '')
          (pkgs.runCommand "monitoring-rules-check" { } ''
            ${lib.getExe' config.services.vmalert.package "vmalert"} -rule=${yaml.generate "rules.yml" config.services.vmalert.instances.main.rules} -dryRun
            touch $out
          '')
          (pkgs.runCommand "monitoring-scrape-config-check" { } ''
            set -o pipefail
            ${lib.getExe' config.services.victoriametrics.package "victoria-metrics"} -promscrape.config=${yaml.generate "scrape.yml" config.services.victoriametrics.prometheusConfig} -dryRun 2>&1 | tee check.log
            if grep -q 'skipping `scrape_config`' check.log; then
              echo "A scrape job failed semantic validation" >&2
              exit 1
            fi
            grep -q -- '-promscrape.config is ok' check.log
            touch $out
          '')
          (pkgs.runCommand "room-alerts-test" { } ''
            cp ${
              yaml.generate "room-alerts-rules.json" (import ../../../../tests/room-alerts.nix { inherit lib; })
            } room-alerts-rules.json
            cp ${../../../../tests/room-alerts.json} room-alerts-tests.json
            ${lib.getExe' config.services.vmalert.package "vmalert-tool"} unittest -disableAlertgroupLabel -files=room-alerts-tests.json
            touch $out
          '')
        ];
      };
    };
}

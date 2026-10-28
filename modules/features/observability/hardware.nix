_: {
  flake.modules.nixos.hardware-monitoring =
    { config, lib, ... }:
    let
      gpuEnabled = lib.elem "nvidia" config.services.xserver.videoDrivers;
      exporters = config.services.prometheus.exporters;
      scrape = name: {
        job_name = name;
        static_configs = [
          {
            targets = [ "${exporters.${name}.listenAddress}:${toString exporters.${name}.port}" ];
            labels.host = config.networking.hostName;
          }
        ];
      };
      rule = alert: expr: duration: severity: summary: {
        inherit alert expr;
        for = duration;
        labels = {
          inherit severity;
          category = "infra";
        };
        annotations = {
          inherit summary;
          dashboard_url = "https://grafana.home.yutakobayashi.com/d/dotnix-hardware-overview";
        };
      };
    in
    {
      config =
        lib.mkIf (config.my.services.monitoring.enable && config.networking.hostName == "B450M-Pro4")
          {
            services = {
              prometheus.exporters = {
                smartctl = {
                  enable = true;
                  listenAddress = "127.0.0.1";
                };
                nvidia-gpu = {
                  enable = gpuEnabled;
                  listenAddress = "127.0.0.1";
                };
              };

              victoriametrics.prometheusConfig.scrape_configs = [
                (scrape "smartctl")
              ]
              ++ lib.optional gpuEnabled (scrape "nvidia-gpu");

              vmalert.instances.main.rules.groups = [
                {
                  name = "hardware";
                  rules = [
                    (rule "HardwareExporterDown" ''up{job=~"smartctl|nvidia-gpu"} == 0'' "5m" "warning"
                      "{{ $labels.host }}: {{ $labels.job }} exporter is unreachable"
                    )
                    (rule "SmartDevicesMissing" "smartctl_devices == 0" "10m" "warning"
                      "{{ $labels.host }}: SMART exporter discovered no disks"
                    )
                    (rule "SmartTelemetryMissing" ''absent(smartctl_device_smart_status{host="B450M-Pro4"})'' "10m"
                      "warning"
                      "B450M-Pro4 disk SMART health telemetry is missing"
                    )
                    (rule "DiskSmartUnhealthy" "smartctl_device_smart_status == 0" "5m" "critical"
                      "{{ $labels.host }} {{ $labels.device }} failed its SMART health check"
                    )
                    (rule "DiskBadSectors"
                      ''smartctl_device_attribute{job="smartctl",attribute_id=~"5|197|198",attribute_value_type="raw"} > 0''
                      "15m"
                      "warning"
                      "{{ $labels.host }} {{ $labels.device }}: {{ $labels.attribute_name }} is non-zero"
                    )
                    (rule "DiskSmartAttributeBelowThreshold"
                      ''smartctl_device_attribute{job="smartctl",attribute_value_type="value"} <= on (job, instance, device, attribute_id) group_left() (smartctl_device_attribute{job="smartctl",attribute_value_type="thresh"} > 0)''
                      "30m"
                      "critical"
                      "{{ $labels.host }} {{ $labels.device }}: {{ $labels.attribute_name }} reached its SMART failure threshold"
                    )
                    (rule "DiskWearoutHigh" "smartctl_device_percentage_used > 80" "1h" "warning"
                      "{{ $labels.host }} {{ $labels.device }} has consumed more than 80% of its rated endurance"
                    )
                    (rule "DiskSpareBlocksLow"
                      "smartctl_device_available_spare < smartctl_device_available_spare_threshold"
                      "15m"
                      "critical"
                      "{{ $labels.host }} {{ $labels.device }} spare capacity is below its device threshold"
                    )
                    (rule "DiskMediaErrors"
                      "smartctl_device_critical_warning > 0 or increase(smartctl_device_media_errors[24h]) > 0"
                      "15m"
                      "critical"
                      "{{ $labels.host }} {{ $labels.device }} reports a critical warning or new media errors"
                    )
                    # Rotation rate distinguishes rotating disks without treating 2.5-inch
                    # HDDs as SSDs. The 70C rule also covers NVMe, which may omit rotation.
                    (rule "DiskTemperatureHigh"
                      ''smartctl_device_temperature{temperature_type="current"} > 70 or (smartctl_device_temperature{temperature_type="current"} > 50 and on (instance, device) smartctl_device_rotation_rate > 0)''
                      "30m"
                      "warning"
                      "{{ $labels.host }} {{ $labels.device }} is too hot ({{ $value }} C)"
                    )
                    (rule "HardwareTemperatureCritical" "node_hwmon_temp_celsius > node_hwmon_temp_crit_celsius" "5m"
                      "critical"
                      "{{ $labels.host }} {{ $labels.chip }}/{{ $labels.sensor }} exceeds its hardware critical temperature"
                    )
                    # Restrict this warning to CPU chips; Wi-Fi, GPU, NVMe and
                    # unlabelled board sensors have different thermal limits.
                    (rule "CpuTemperatureHigh"
                      ''(node_hwmon_temp_celsius{job="node"} > 80 or node_hwmon_temp_celsius{job="node"} >= node_hwmon_temp_crit_celsius{job="node"} - 15) and on (job, instance, chip) node_hwmon_chip_names{job="node",chip_name=~"coretemp|k10temp|zenpower|cpu_thermal"}''
                      "15m"
                      "warning"
                      "{{ $labels.host }} CPU {{ $labels.chip }}/{{ $labels.sensor }} is above 80 C or within 15 C of its critical temperature"
                    )
                    (rule "MemoryEccCorrectableErrors"
                      ''increase(node_edac_correctable_errors_total{job="node"}[1h]) > 0''
                      "5m"
                      "warning"
                      "{{ $labels.host }} EDAC reported new corrected memory errors in the last hour; inspect kernel logs"
                    )
                    (rule "MemoryEccUncorrectableErrors"
                      ''increase(node_edac_uncorrectable_errors_total{job="node"}[1h]) > 0''
                      "0m"
                      "critical"
                      "{{ $labels.host }} EDAC reported new uncorrected memory errors in the last hour; inspect kernel logs immediately"
                    )
                  ]
                  ++ lib.optionals gpuEnabled [
                    (rule "GpuTemperatureHigh" "nvidia_smi_temperature_gpu > 85" "15m" "warning"
                      "{{ $labels.host }} GPU {{ $labels.uuid }} exceeds 85 C"
                    )
                    (rule "GpuTemperatureHigh" "nvidia_smi_temperature_gpu > 92" "5m" "critical"
                      "{{ $labels.host }} GPU {{ $labels.uuid }} exceeds 92 C"
                    )
                    (rule "GpuMemoryUsageHigh" "100 * nvidia_smi_memory_used_bytes / nvidia_smi_memory_total_bytes > 95"
                      "15m"
                      "warning"
                      "{{ $labels.host }} GPU {{ $labels.uuid }} memory is above 95%"
                    )
                    (rule "GpuMetricsMissing" ''absent(nvidia_smi_gpu_info{host="B450M-Pro4"})'' "10m" "warning"
                      "B450M-Pro4 GPU telemetry is missing"
                    )
                  ];
                }
              ];
            };
          };
    };
}

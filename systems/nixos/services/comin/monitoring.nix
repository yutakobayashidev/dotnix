{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

let
  monitoredHosts = [
    "UM790-Pro"
    "B450M-Pro4"
    "pi5"
    "M2-MacBook-Air"
  ];
  linuxMachines = inputs.self.outputs.nixosConfigurations;
  darwinMachines = inputs.self.outputs.darwinConfigurations;

  textfileDir = "/var/lib/node-exporter-textfile";
  expectedCommitMetric = "comin_expected_commit_info";
  dotnixUrl = "https://github.com/yutakobayashidev/dotnix";

  nodeExporterUser = config.services.prometheus.exporters.node.user;
  nodeExporterGroup = config.services.prometheus.exporters.node.group;
in
{
  services = {
    victoriametrics.prometheusConfig.scrape_configs = [
      {
        job_name = "comin";
        static_configs = lib.mapAttrsToList (
          name: value:
          let
            inherit (value.config.services.comin.exporter) listen_address port;
            listenAddress = if listen_address == "" then "localhost" else listen_address;
            host = if name == config.networking.hostName then listenAddress else name;
          in
          {
            targets = [ "${host}:${toString port}" ];
            labels = {
              host = name;
              always_on = lib.boolToString (lib.elem name config.my.services.monitoring.alwaysOnHosts);
            };
          }
        ) (lib.filterAttrs (name: _: lib.elem name monitoredHosts) (linuxMachines // darwinMachines));
      }
    ];

    vmalert.instances.main.rules.groups = [
      {
        name = "comin";
        rules = [
          {
            alert = "CominDown";
            expr = ''up{job="comin",always_on="true"} == 0'';
            for = "15m";
            labels.severity = "warning";
            annotations.summary = "Comin on {{ $labels.host }} is not responding";
          }
          {
            alert = "CominDeploymentFailed";
            expr = ''comin_deployment_info{status="failed"} == 1'';
            for = "5m";
            labels.severity = "warning";
            annotations.summary = "Comin deployment failed on {{ $labels.host }} ({{ $labels.commit_id }})";
          }
          {
            alert = "CominEvalFailed";
            expr = "comin_last_eval_failed == 1";
            for = "15m";
            labels.severity = "warning";
            annotations.summary = "Comin cannot evaluate the configuration on {{ $labels.host }}";
          }
          {
            alert = "CominBuildFailed";
            expr = "comin_last_build_failed == 1";
            for = "15m";
            labels.severity = "warning";
            annotations.summary = "Comin cannot build the configuration on {{ $labels.host }}";
          }
          {
            alert = "CominFetchFailed";
            expr = ''comin_last_fetch_failed{always_on="true"} == 1'';
            for = "1h";
            labels.severity = "warning";
            annotations.summary = "Comin on {{ $labels.host }} cannot fetch {{ $labels.remote_name }}";
          }
          {
            alert = "CominSuspended";
            expr = ''comin_is_suspended{always_on="true"} == 1'';
            for = "15m";
            labels.severity = "warning";
            annotations.summary = "Comin on {{ $labels.host }} is suspended";
          }
          {
            alert = "CominStalled";
            # Preserve host for notification routing and host-down inhibition.
            expr = ''sum by (host, instance) (increase(comin_fetch_count{always_on="true"}[6h])) == 0 unless on (instance) comin_is_suspended == 1'';
            for = "30m";
            labels.severity = "warning";
            annotations.summary = "Comin on {{ $labels.host }} has not fetched for six hours";
          }
          {
            alert = "CominRebootRequired";
            expr = "comin_need_to_reboot == 1";
            for = "7d";
            labels.severity = "warning";
            annotations.summary = "{{ $labels.host }} has needed a reboot for seven days";
          }
        ];
      }
    ];

    # Keep the existing dashboard's commit comparison. Do not page on commit
    # differences: a new commit may evaluate to the same system for this host.
    prometheus.exporters.node.extraFlags = [
      "--collector.textfile.directory=${textfileDir}"
    ];

  };

  systemd = {
    tmpfiles.rules = [
      "d ${textfileDir} 0700 ${nodeExporterUser} ${nodeExporterGroup} -"
    ];
    services.comin-expected-commit = {
      description = "Publish dotnix main HEAD as a Prometheus textfile metric";
      serviceConfig = {
        Type = "oneshot";
        User = nodeExporterUser;
        Group = nodeExporterGroup;
        ExecStart =
          let
            publishExpectedCommit = pkgs.writeShellApplication {
              name = "comin-publish-expected-commit";
              runtimeInputs = [
                pkgs.coreutils
                pkgs.git
              ];
              text = ''
                sha=$(git ls-remote ${dotnixUrl} refs/heads/main | cut -f1)
                if [ -z "$sha" ]; then
                  echo "git ls-remote returned no SHA for refs/heads/main" >&2
                  exit 1
                fi

                tmp=$(mktemp ${textfileDir}/${expectedCommitMetric}.XXXXXX.tmp)
                {
                  printf '# HELP ${expectedCommitMetric} Latest commit on the configured branch, polled by systemd timer.\n'
                  printf '# TYPE ${expectedCommitMetric} gauge\n'
                  printf '${expectedCommitMetric}{branch="main",commit_id="%s"} 1\n' "$sha"
                } > "$tmp"
                mv "$tmp" ${textfileDir}/${expectedCommitMetric}.prom
              '';
            };
          in
          lib.getExe publishExpectedCommit;
      };
    };
    timers.comin-expected-commit = {
      description = "Refresh dotnix main HEAD metric for drift detection";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "1m";
        OnUnitActiveSec = "1m";
      };
    };
  };
}

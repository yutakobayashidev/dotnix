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
  services.prometheus.scrapeConfigs = [
    {
      job_name = "comin";
      static_configs = [
        {
          targets = lib.mapAttrsToList (
            name: value:
            let
              inherit (value.config.services.comin.exporter) listen_address port;
              listenAddress = if listen_address == "" then "localhost" else listen_address;
              host = if name == config.networking.hostName then listenAddress else name;
            in
            "${host}:${toString port}"
          ) (lib.filterAttrs (name: _: lib.elem name monitoredHosts) (linuxMachines // darwinMachines));
        }
      ];
    }
  ];

  services.prometheus.exporters.node.extraFlags = [
    "--collector.textfile.directory=${textfileDir}"
  ];

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

{
  config,
  lib,
  pkgs,
  ...
}:

let
  rules = (pkgs.formats.yaml { }).generate "codex-reset.yaml" {
    groups = [
      {
        name = "codex-reset-events";
        interval = "30s";
        rules = [
          {
            alert = "CodexResetCompleted";
            expr = ''
              sum by (host, user_id, credit_id) (
                count_over_time(
                  {job="codex-limit-auto-reset",event="credit_redemption_result"}
                  | json outcome="outcome", credit_id="credit_id"
                  | outcome="reset" | credit_id!="" | __error__="" [15m]
                )
              ) > 0
            '';
            labels = {
              severity = "info";
              kind = "event";
            };
            annotations = {
              summary = "Codex rate limit reset completed";
              description = "Credit: {{ $labels.credit_id }}";
              dashboard_url = "https://grafana.home.yutakobayashi.com/d/codex-reset-history";
            };
          }
        ];
      }
    ];
  };
in
{
  config =
    lib.mkIf
      (config.my.services.monitoring.enable && config.my.services.alertmanager.notifications.enable)
      {
        services.loki.configuration.ruler = {
          storage = {
            type = "local";
            local.directory = pkgs.linkFarm "codex-reset-rules" [
              {
                # Loki's tenant ID is "fake" when auth_enabled = false.
                name = "fake/codex-reset.yaml";
                path = rules;
              }
            ];
          };
          rule_path = "${config.services.loki.dataDir}/ruler";
          alertmanager_url = "http://127.0.0.1:${toString config.services.prometheus.alertmanager.port}";
          ring.kvstore.store = "inmemory";
        };
      };
}

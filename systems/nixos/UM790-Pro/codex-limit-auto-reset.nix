{ config, ... }:

{
  my.services.alloy.configs.codex-limit-auto-reset = ''
    loki.relabel "codex_limit_auto_reset" {
      forward_to = []
      rule {
        source_labels = ["__journal__uid"]
        target_label = "user_id"
      }
    }

    loki.source.journal "codex_limit_auto_reset" {
      forward_to = [loki.process.codex_limit_auto_reset.receiver]
      matches = "_SYSTEMD_USER_UNIT=codex-limit-auto-reset.service"
      max_age = "168h"
      relabel_rules = loki.relabel.codex_limit_auto_reset.rules
      labels = {
        job = "codex-limit-auto-reset",
        host = "${config.networking.hostName}",
        unit = "codex-limit-auto-reset.service",
      }
    }

    loki.process "codex_limit_auto_reset" {
      forward_to = [loki.write.default.receiver]
      stage.json {
        expressions = { event = "event", level = "level" }
        drop_malformed = true
      }
      stage.labels {
        values = { event = "", level = "" }
      }
      stage.match {
        selector = "{job=\"codex-limit-auto-reset\", event!~\"credit_redemption_attempt|credit_redemption_result|credit_redemption_error|check_failed|next_check\"}"
        action = "drop"
        drop_counter_reason = "not_reset_event"
      }
    }
  '';
}

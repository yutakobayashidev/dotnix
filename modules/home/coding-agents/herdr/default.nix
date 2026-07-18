{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.programs.herdr;
  tomlFormat = pkgs.formats.toml { };

  focusAttentionAgent = pkgs.writeShellApplication {
    name = "herdr-focus-attention-agent";
    runtimeInputs = [
      cfg.package
      pkgs.jq
    ];
    text = ''
      set -euo pipefail

      agents_json="$(herdr agent list)"

      pane_ids=()
      selected_status=""
      statuses=(blocked "done")
      for status in "''${statuses[@]}"; do
        while IFS= read -r pane_id; do
          [ -n "$pane_id" ] && pane_ids+=("$pane_id")
        done < <(printf '%s\n' "$agents_json" | jq -r --arg status "$status" '.result.agents[] | select(.agent_status == $status) | .pane_id')
        if [ "''${#pane_ids[@]}" -gt 0 ]; then
          selected_status="$status"
          break
        fi
      done

      if [ "''${#pane_ids[@]}" -eq 0 ]; then
        echo "herdr-focus-attention-agent: no blocked or unread agent panes"
        exit 0
      fi

      current="$(printf '%s\n' "$agents_json" | jq -r '.result.agents[] | select(.focused == true) | .pane_id')"

      next_index=0
      if [ -n "$current" ]; then
        for i in "''${!pane_ids[@]}"; do
          if [ "''${pane_ids[$i]}" = "$current" ]; then
            next_index=$(( (i + 1) % ''${#pane_ids[@]} ))
            break
          fi
        done
      fi

      target="''${pane_ids[$next_index]}"
      herdr agent focus "$target"
      echo "herdr-focus-attention-agent: focused $target ($selected_status $((next_index + 1))/''${#pane_ids[@]})"
    '';
  };

  defaultSettings = {
    onboarding = false;

    theme = {
      name = "catppuccin";
      auto_switch = false;
    };

    keys = {
      prefix = "ctrl+t";

      new_tab = "f2";
      previous_tab = "f3";
      next_tab = "f4";
      reload_config = "f5";
      detach = "f6";
      edit_scrollback = "f7";
      rename_tab = "f8";

      split_horizontal = "shift+f2";
      split_vertical = "ctrl+f2";
      close_pane = "ctrl+f6";

      focus_pane_left = "shift+left";
      focus_pane_down = "shift+down";
      focus_pane_up = "shift+up";
      focus_pane_right = "shift+right";

      previous_workspace = "prefix+up";
      next_workspace = "prefix+down";
      previous_agent = "prefix+comma";
      next_agent = "prefix+.";
      switch_workspace = "prefix+shift+1..9";
      last_pane = "prefix+o";

      command = [
        {
          key = "prefix+l";
          type = "popup";
          command = "lazygit";
        }
        {
          key = "prefix+b";
          type = "popup";
          command = "btop";
        }
        {
          key = "prefix+shift+u";
          type = "shell";
          command = "herdr-focus-attention-agent";
          description = "Focus the next blocked or unread Herdr agent pane";
        }
      ];
    };

    ui = {
      confirm_close = true;
      prompt_new_tab_name = false;
      show_agent_labels_on_pane_borders = true;
      sound.enabled = false;
    };
  };

  configFile = tomlFormat.generate "herdr-config.toml" (
    lib.recursiveUpdate defaultSettings cfg.settings
  );
in
{
  options.my.programs.herdr = {
    enable = lib.mkEnableOption "Herdr";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.llm-agents.herdr;
      defaultText = lib.literalExpression "pkgs.llm-agents.herdr";
      description = "Package containing the {command}`herdr` binary.";
    };

    settings = lib.mkOption {
      inherit (tomlFormat) type;
      default = { };
      description = "Herdr configuration written to `~/.config/herdr/config.toml`.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      cfg.package
      focusAttentionAgent
    ];

    xdg.configFile."herdr/config.toml".source = configFile;
  };
}

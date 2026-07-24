_:

{
  flake.modules.homeManager."herdr" =
    {
      config,
      lib,
      pkgs,
      inputs,
      ...
    }:

    let
      cfg = config.my.programs.herdr;
      tomlFormat = pkgs.formats.toml { };

      herdrSkillSrc = builtins.path {
        path = inputs.herdr-skill;
        name = "herdr-skill-no-symlinks";
        filter = _path: type: type != "symlink";
      };

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

      # Adapted from miyagawa's Claude Code session-fork helper:
      # https://gist.github.com/miyagawa/cb1a9f6c8695d1219efba0c66d5f78f7
      # Adapted from miyagawa's Claude Code session-fork helper:
      # https://gist.github.com/miyagawa/cb1a9f6c8695d1219efba0c66d5f78f7
      forkAgentSession = pkgs.writeShellApplication {
        name = "herdr-fork-agent-session";
        runtimeInputs = [
          cfg.package
          pkgs.jq
        ];
        text = ''
          set -euo pipefail

          if [ "''${HERDR_ENV:-}" != "1" ]; then
            echo "herdr-fork-agent-session: not running inside Herdr (HERDR_ENV != 1)" >&2
            exit 1
          fi

          direction="''${1:-right}"
          case "$direction" in
            right | down) ;;
            *)
              echo "herdr-fork-agent-session: direction must be 'right' or 'down', got '$direction'" >&2
              exit 1
              ;;
          esac

          focused="$(herdr agent list | jq -cer '.result.agents[] | select(.focused == true)')" || {
            echo "herdr-fork-agent-session: no focused Herdr agent found" >&2
            exit 1
          }

          agent="$(printf '%s\n' "$focused" | jq -r '.agent')"
          session_id="$(printf '%s\n' "$focused" | jq -r '.agent_session.value // empty')"

          if [ -z "$session_id" ]; then
            echo "herdr-fork-agent-session: focused $agent agent has no session ID" >&2
            exit 1
          fi

          case "$agent" in
            claude)
              session_id="''${CLAUDE_CODE_SESSION_ID:-$session_id}"
              printf -v agent_command 'claude --resume %q --fork-session' "$session_id"
              ;;
            codex)
              printf -v agent_command 'codex fork %q' "$session_id"
              ;;
            *)
              echo "herdr-fork-agent-session: unsupported focused agent '$agent'" >&2
              exit 1
              ;;
          esac

          pane="$(herdr pane split --current --direction "$direction" --cwd "$PWD" --no-focus | jq -er '.result.pane.pane_id')"
          herdr pane run "$pane" "$agent_command"
          echo "forked $agent session $session_id -> pane $pane"
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
            {
              key = "prefix+f";
              type = "shell";
              command = "herdr-fork-agent-session";
              description = "Fork the focused Claude Code or Codex session to the right";
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
          forkAgentSession
        ];

        xdg.configFile."herdr/config.toml".source = configFile;

        programs.agent-skills = {
          sources.herdr.path = herdrSkillSrc;

          skills.explicit.herdr = {
            from = "herdr";
            path = ".";
          };
        };
      };
    };
}

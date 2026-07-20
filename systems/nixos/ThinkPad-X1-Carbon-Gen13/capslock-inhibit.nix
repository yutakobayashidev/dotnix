{ pkgs, ... }:

let
  capslockInhibit = pkgs.writeShellApplication {
    name = "capslock-inhibit";

    runtimeInputs = [
      pkgs.coreutils
      pkgs.systemd
    ];

    text = ''
      inhibitor_pid=""

      stop_inhibitor() {
        if [[ -z "$inhibitor_pid" ]]; then
          return
        fi

        kill "$inhibitor_pid" 2>/dev/null || true
        wait "$inhibitor_pid" 2>/dev/null || true
        inhibitor_pid=""
      }

      caps_lock_enabled() {
        local led

        for led in /sys/class/leds/*::capslock/brightness; do
          [[ -e "$led" ]] || continue

          if [[ "$(cat "$led")" != "0" ]]; then
            return 0
          fi
        done

        return 1
      }

      trap stop_inhibitor EXIT
      trap 'exit 0' INT TERM

      while true; do
        if [[ -n "$inhibitor_pid" ]] && ! kill -0 "$inhibitor_pid" 2>/dev/null; then
          wait "$inhibitor_pid" 2>/dev/null || true
          inhibitor_pid=""
        fi

        if caps_lock_enabled; then
          if [[ -z "$inhibitor_pid" ]]; then
            systemd-inhibit \
              --what=idle:sleep \
              --mode=block \
              --why="Caps Lock is enabled" \
              sleep infinity &

            inhibitor_pid=$!
            echo "Caps Lock ON: sleep inhibited"
          fi
        elif [[ -n "$inhibitor_pid" ]]; then
          stop_inhibitor
          echo "Caps Lock OFF: sleep inhibition released"
        fi

        sleep 1
      done
    '';
  };
in
{
  systemd.user.services.capslock-inhibit = {
    description = "Prevent sleep while Caps Lock is enabled";

    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];

    serviceConfig = {
      ExecStart = "${capslockInhibit}/bin/capslock-inhibit";
      Restart = "on-failure";
      RestartSec = 1;
    };
  };
}

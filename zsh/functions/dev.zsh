#!/usr/bin/env zsh

# dev: VSCode風マルチプロジェクト開発セッション管理
# ┌──────┬────────────────┐
# │      │                │
# │keifu │    nvim         │
# │      │                │
# │      ├────────────────┤
# │      │    shell        │
# └──────┴────────────────┘

function dev() {
  local SESSION="dev"
  local CONF_DIR="$HOME/.config/dev-tmux"
  mkdir -p "$CONF_DIR"

  # ── ユーティリティ ──

  _dev_load_conf() {
    local name="$1"
    PROJECT_DIR="$HOME"
    SHELL_CMD=""
    [[ -f "$CONF_DIR/${name}.conf" ]] && source "$CONF_DIR/${name}.conf"
  }

  _dev_save_conf() {
    local name="$1"
    local f="$CONF_DIR/${name}.conf"
    cat > "$f" <<EOF
# プロジェクト: $name
PROJECT_DIR="$PROJECT_DIR"
SHELL_CMD="$SHELL_CMD"
EOF
  }

  # ── ウィンドウ作成 ──

  _dev_create_window() {
    local name="$1" is_first="$2"
    _dev_load_conf "$name"

    local dir="${(e)PROJECT_DIR}"

    if [[ "$is_first" == "first" ]]; then
      tmux new-session -d -s "$SESSION" -n "$name" -c "$dir"
    else
      tmux new-window -t "$SESSION" -n "$name" -c "$dir"
    fi

    local t="$SESSION:$name"

    # 左右分割: ペイン1=左(keifu), ペイン2=右
    tmux split-window -h -t "${t}.1" -c "$dir" -l 90%
    # 右を上下分割: ペイン2=右上(nvim), ペイン3=右下(shell, 30%)
    tmux split-window -v -t "${t}.2" -c "$dir" -l 30%

    # ペイン1: keifu
    tmux send-keys -t "${t}.1" "keifu" Enter
    # ペイン2: nvim (ディレクトリを開く)
    tmux send-keys -t "${t}.2" "nvim ." Enter
    # ペイン3: SHELL_CMD
    [[ -n "$SHELL_CMD" ]] && tmux send-keys -t "${t}.3" "$SHELL_CMD" Enter

    # nvimにフォーカス
    tmux select-pane -t "${t}.2"
  }

  # ── dev (引数なし): 全プロジェクトを開く ──

  _dev_default() {
    local names=()
    if ls "$CONF_DIR"/*.conf &>/dev/null; then
      for f in "$CONF_DIR"/*.conf; do
        names+=("$(basename "$f" .conf)")
      done
    fi

    if [[ ${#names[@]} -eq 0 ]]; then
      echo "プロジェクトがありません"
      echo "  dev add [name] [dir]  で作成"
      return 0
    fi

    if tmux has-session -t "$SESSION" 2>/dev/null; then
      local existing
      existing=$(tmux list-windows -t "$SESSION" -F '#W')
      for name in "${names[@]}"; do
        if ! echo "$existing" | grep -qx "$name"; then
          _dev_create_window "$name" "add"
          echo "  [${name}] 追加"
        fi
      done
      if [[ -n "${TMUX:-}" ]]; then
        tmux switch-client -t "$SESSION"
      else
        tmux attach-session -t "$SESSION"
      fi
    else
      local first=true
      for name in "${names[@]}"; do
        if [[ "$first" == true ]]; then
          _dev_create_window "$name" "first"
          first=false
        else
          _dev_create_window "$name" "add"
        fi
      done
      tmux select-window -t "$SESSION:${names[1]}"
      tmux attach-session -t "$SESSION"
    fi
  }

  # ── dev <name>: プロジェクトを開く ──

  _dev_open() {
    local name="$1"

    if [[ ! -f "$CONF_DIR/${name}.conf" ]]; then
      echo "  未登録: $name"
      echo "  dev add $name  で作成してください"
      return 1
    fi

    if ! tmux has-session -t "$SESSION" 2>/dev/null; then
      _dev_create_window "$name" "first"
    else
      if tmux list-windows -t "$SESSION" -F '#W' | grep -qx "$name"; then
        tmux select-window -t "$SESSION:$name"
      else
        _dev_create_window "$name" "add"
      fi
    fi

    if [[ -n "${TMUX:-}" ]]; then
      tmux switch-client -t "$SESSION:$name"
    else
      tmux attach-session -t "$SESSION:$name"
    fi
  }

  # ── dev add [name] [dir] ──

  _dev_add() {
    local name="${1:-$(basename "$(pwd)")}"
    local dir="${2:-$(pwd)}"

    if [[ -f "$CONF_DIR/${name}.conf" ]]; then
      echo "  既に存在: $name"
      echo "  dev config  → 設定  /  dev $name  → 開く"
      return 0
    fi

    PROJECT_DIR="$dir"
    SHELL_CMD=""
    _dev_save_conf "$name"

    echo "  作成: $name ($dir)"

    if tmux has-session -t "$SESSION" 2>/dev/null; then
      _dev_create_window "$name" "add"
      echo "  ウィンドウ追加済み"
      [[ -n "${TMUX:-}" ]] && tmux select-window -t "$SESSION:$name"
    else
      echo "  dev config → 設定  /  dev → 起動"
    fi
  }

  # ── dev edit <name> ──

  _dev_edit() {
    local name="$1"
    if [[ ! -f "$CONF_DIR/${name}.conf" ]]; then
      echo "  設定がありません: $name"
      return 1
    fi
    "${EDITOR:-nvim}" "$CONF_DIR/${name}.conf"
  }

  # ── dev config [name] ──

  _dev_config() {
    local name=""
    if [[ -n "${1:-}" ]]; then
      name="$1"
    elif [[ -n "${TMUX:-}" ]]; then
      name=$(tmux display-message -p '#W')
    else
      name=$(basename "$(pwd)")
    fi

    if [[ ! -f "$CONF_DIR/${name}.conf" ]]; then
      echo "  設定がありません: $name"
      echo "  dev add で作成してください"
      return 1
    fi

    _dev_load_conf "$name"
    local dir_display="${(e)PROJECT_DIR}"
    dir_display="${dir_display/#$HOME/~}"

    while true; do
      echo ""
      echo "[$name] ($dir_display)"
      echo ""
      echo "  1) shell cmd: ${SHELL_CMD:-(未設定)}"
      echo ""
      echo "  e) エディタ  q) 終了"
      echo ""
      printf "選択: "
      read -r choice

      case "$choice" in
        1)
          echo "  (空Enter = クリア)"
          printf "  コマンド [${SHELL_CMD:-(なし)}]: "
          read -r val
          SHELL_CMD="$val"
          _dev_save_conf "$name"
          echo "  → 保存"
          ;;
        e) "${EDITOR:-nvim}" "$CONF_DIR/${name}.conf"; _dev_load_conf "$name" ;;
        q|"") break ;;
        *) echo "  1, e, q のいずれか" ;;
      esac
    done

    echo "  反映: dev restart $name / Option+R"
  }

  # ── dev rm <name> ──

  _dev_rm() {
    local name="$1"
    if [[ ! -f "$CONF_DIR/${name}.conf" ]]; then
      echo "  設定がありません: $name"
      return 1
    fi
    if tmux list-windows -t "$SESSION" -F '#W' 2>/dev/null | grep -qx "$name"; then
      tmux kill-window -t "$SESSION:$name"
      echo "  [${name}] stopped"
    fi
    rm "$CONF_DIR/${name}.conf"
    echo "  [${name}] removed"
  }

  # ── dev restart [name] ──

  _dev_restart() {
    local name="${1:-}"
    [[ -z "$name" ]] && [[ -n "${TMUX:-}" ]] && name=$(tmux display-message -p '#W')
    [[ -z "$name" ]] && { echo "  名前を指定してください"; return 1; }

    local t="$SESSION:$name"

    if ! tmux list-windows -t "$SESSION" -F '#W' 2>/dev/null | grep -qx "$name"; then
      echo "  [${name}] not running"
      return 1
    fi

    _dev_load_conf "$name"

    # ペイン3(shell)を再起動
    tmux send-keys -t "${t}.3" C-c
    sleep 0.3
    tmux send-keys -t "${t}.3" 'clear' Enter

    [[ -n "$SHELL_CMD" ]] && tmux send-keys -t "${t}.3" "$SHELL_CMD" Enter

    echo "  [${name}] restarted"
  }

  # ── dev stop [name] ──

  _dev_stop() {
    local name="${1:-}"
    if [[ -z "$name" ]]; then
      tmux kill-session -t "$SESSION" 2>/dev/null && echo "  session stopped" || echo "  not running"
    else
      if tmux list-windows -t "$SESSION" -F '#W' 2>/dev/null | grep -qx "$name"; then
        tmux kill-window -t "$SESSION:$name"
        echo "  [${name}] stopped"
      else
        echo "  [${name}] not running"
      fi
    fi
  }

  # ── dev ls ──

  _dev_ls() {
    local running=""
    tmux has-session -t "$SESSION" 2>/dev/null && \
      running=$(tmux list-windows -t "$SESSION" -F '#W' 2>/dev/null || true)

    local found=false
    if ls "$CONF_DIR"/*.conf &>/dev/null; then
      for conf in "$CONF_DIR"/*.conf; do
        found=true
        local name
        name=$(basename "$conf" .conf)
        PROJECT_DIR="$HOME"
        SHELL_CMD=""
        source "$conf"
        local d="${(e)PROJECT_DIR}"
        d="${d/#$HOME/~}"
        local mark="  "
        echo "$running" | grep -qx "$name" 2>/dev/null && mark="▶ "
        echo "${mark}${name}  →  ${d}"
        [[ -n "$SHELL_CMD" ]] && echo "    shell: $SHELL_CMD"
      done
    fi
    [[ "$found" == false ]] && echo "  プロジェクトなし。 dev add で作成"
  }

  # ── dev clear [name] ──

  _dev_clear() {
    local name="${1:-}"
    [[ -z "$name" ]] && { [[ -n "${TMUX:-}" ]] && name=$(tmux display-message -p '#W') || { echo "  名前を指定してください"; return 1; }; }
    for pane in $(tmux list-panes -t "$SESSION:$name" -F '#{pane_id}' 2>/dev/null); do
      tmux send-keys -t "$pane" 'clear' Enter
      tmux clear-history -t "$pane"
    done
    echo "  [${name}] cleared"
  }

  # ── メイン ──

  case "${1:-}" in
    add)     shift; _dev_add "$@" ;;
    edit)    [[ -z "${2:-}" ]] && { echo "Usage: dev edit <name>"; return 1; }; _dev_edit "$2" ;;
    config)  _dev_config "${2:-}" ;;
    rm|remove) [[ -z "${2:-}" ]] && { echo "Usage: dev rm <name>"; return 1; }; _dev_rm "$2" ;;
    restart) shift; _dev_restart "$@" ;;
    stop)    _dev_stop "${2:-}" ;;
    ls|list) _dev_ls ;;
    status)  if tmux has-session -t "$SESSION" 2>/dev/null; then tmux list-windows -t "$SESSION" -F "  #W (#{window_panes} panes)"; else echo "  not running"; fi ;;
    clear)   _dev_clear "${2:-}" ;;
    help|-h|--help)
      cat << 'HELP'
dev - VSCode風 tmux開発セッション管理

  dev                    全プロジェクトを開く
  dev <name>             特定プロジェクトを開く
  dev add [name] [dir]   プロジェクト作成
  dev config [name]      シェルコマンド設定
  dev edit <name>        設定ファイルを編集
  dev rm <name>          プロジェクト削除
  dev restart [name]     シェルペインを再起動
  dev stop [name]        終了
  dev ls                 一覧
  dev status             実行中ウィンドウ
  dev clear [name]       全ペインクリア

tmuxキーバインド:
  Option+C   現在のペインをクリア
  Option+D   全ペインをクリア
  Option+R   ペイン3(shell)再起動
  Option+S   ペイン3(shell)停止

  ┌──────┬────────────────┐
  │      │                │
  │keifu │    nvim         │
  │      │                │
  │      ├────────────────┤
  │      │    shell        │
  └──────┴────────────────┘
HELP
      ;;
    "") _dev_default ;;
    *)  _dev_open "$1" ;;
  esac
}

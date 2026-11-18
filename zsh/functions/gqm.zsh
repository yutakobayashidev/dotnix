#!/usr/bin/env zsh

# ghq の remote URL に合わせて配置を点検・移動する。
function gqm() {
  emulate -L zsh
  local mode=dry-run arg repos repo output
  local -i planned=0 moved=0 unchanged=0 skipped=0 failed=0
  for arg in "$@"; do
    if [[ "$arg" == -h || "$arg" == --help ]]; then
      print -r -- 'Usage: gqm [--dry-run | --apply]

ghq 管理下のリポジトリを remote URL に合う配置へ整理する。
  --dry-run  移動予定を表示する（引数なしの既定動作）
  --apply    移動可能なリポジトリを確認なしで移動する
  -h, --help ヘルプを表示する

移動先が既にある場合は上書きしない。worktree・submodule は単独移動しない。
終了コード: 0=完了、1=点検・移動エラーあり、2=引数エラー。'
      return 0
    fi
  done
  if (( $# > 1 )); then
    print -u2 -- 'gqm: --dry-run または --apply のいずれかを指定してください。'
    return 2
  fi
  case "${1:-}" in
    ''|--dry-run) ;;
    --apply) mode=apply ;;
    *) print -u2 -- "gqm: 不明な引数: $1（gqm --help を参照）"; return 2 ;;
  esac
  if ! repos=$(command ghq list -p); then
    print -u2 -- 'gqm: リポジトリ一覧を取得できませんでした。'
    return 1
  fi
  # 一覧を先に確定し、移動中の列挙変化や stdin の消費を避ける。
  for repo in "${(@f)repos}"; do
    [[ -n "$repo" ]] || continue
    if [[ -f "$repo/.git" ]]; then
      print -r -- "SKIP (linked checkout): $repo"
      (( skipped += 1 ))
      continue
    fi
    if output=$(command ghq migrate --dry-run "$repo" 2>&1); then
      (( planned += 1 ))
      print -r -- "$output"
      if [[ "$mode" == apply ]]; then
        if [[ "$PWD" == "$repo" || "$PWD" == "$repo/"* ]]; then
          print -u2 -- "gqm: 現在の作業ディレクトリを含むため移動しません: $repo（外へ cd して再実行）"
          (( failed += 1 ))
        elif command ghq migrate -y "$repo"; then
          (( moved += 1 ))
        else
          (( failed += 1 ))
        fi
      fi
    elif [[ "$output" == *'repository is already at the correct location:'* ]]; then
      # ghq は配置済みでも非ゼロ終了するため、通常の点検結果として扱う。
      (( unchanged += 1 ))
    else
      print -u2 -r -- "gqm: $repo" "$output"
      (( failed += 1 ))
    fi
  done
  print -r -- "mode=$mode candidates=$planned moved=$moved unchanged=$unchanged skipped=$skipped errors=$failed"
  (( failed == 0 ))
}

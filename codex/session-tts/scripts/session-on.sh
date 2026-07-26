#!/bin/bash
# SessionStart hook handler.
#
# Two responsibilities:
#   1. Assign a voice to this session (rotating through the configured slots).
#   2. Inject mid-turn narration guidance into Codex's context.

set -e

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
session_tts_root="$(cd "$script_dir/.." && pwd)"

# shellcheck source=codex/session-tts/scripts/lib/voice-context.sh
. "$script_dir/lib/voice-context.sh"

session_id=$(jq -r '.session_id // empty')
if [ -z "$session_id" ]; then
  exit 0
fi

data_dir=$(session_tts_data_dir)
sessions_dir="$data_dir/sessions"
index_file="$data_dir/index"
session_file="$sessions_dir/$session_id"

mkdir -p "$sessions_dir"

# --- inject mid-turn narration guidance into Codex's context ---
session_tts_root_for_instr="$session_tts_root"
instructions=$(
  cat <<EOF
[session-tts] TTS is enabled for this session.

You can deliver **verbal task-progress reports during autonomous, multi-step
work** so the user can follow your progress by ear without reading every
message.

**Invoke via the Bash tool** (synchronous — do NOT pass \`run_in_background\`):

\`\`\`
Bash(
  command: bash "${session_tts_root_for_instr}/scripts/say.sh" "<lead-in + body, one short Japanese phrase>",
  description: "TTS report"
)
\`\`\`

The call blocks until synthesis and playback finish. Keep each phrase short
(under ~100 Japanese characters) so the turn doesn't stall, and only narrate
at real milestones — see the list below.

Call this at these moments:
EOF
  cat <<'EOF'
- **Task transitions**: when you finish a task and move on to the next
- **Problems**: when a task hits an unexpected obstacle, error, or blocker
- **Important findings**: when investigation surfaces a notable result
- **Direction changes**: when you revise the plan or pivot the approach

Length: keep each prompt under ~100 Japanese characters.

**Format**: every phrase must begin with a brief lead-in (枕詞) before
the body, so the listener has a beat to register that an update is
coming instead of being dropped into content cold. Match the lead-in
to the moment:

- transitions: 「報告です。」「完了です。」「進捗です。」
- problems: 「問題発生です。」「エラーです。」
- findings: 「発見です。」「気づきです。」
- direction changes: 「方針転換です。」「アプローチを変えます。」

Examples (lead-in + body, adapt to the actual work):
- (transition) 「報告です。ログイン機能のテストが全て通りました。次はAPI部分の実装に入ります」
- (problem) 「問題発生です。ビルドが3つのmoduleで失敗しています。原因を調べます」
- (finding) 「発見です。キャッシュ設定が原因でレスポンスが遅くなっていました」
- (pivot) 「方針転換です。最初のREST実装は要件に合わないのでGraphQLに切り替えます」

Avoid:
- Mechanical tool announcements (e.g.「ファイルを読みます」「Bash実行します」)
- Per-tool narration; report at the milestone, not at each step
- The final response of a turn (Stop hook narrates the final assistant
  message automatically)

say.sh itself is a no-op if TTS has been silenced via the session-tts skill,
so it's safe to call it without checking silence status.
EOF
)

# --- pick a voice for this session (only if not already assigned) -----
newly_assigned=0
if [ ! -f "$session_file" ]; then
  prev=$(cat "$index_file" 2>/dev/null || echo -1)
  case "$prev" in '' | *[!0-9-]*) prev=-1 ;; esac
  next=$(((prev + 1) % 3))
  case "$next" in
  0) speaker_id=888753760 ;; # まお（ノーマル）
  1) speaker_id=888753761 ;; # まお（ふつー）
  2) speaker_id=888753762 ;; # まお（あまあま）
  *) speaker_id=888753760 ;;
  esac
  echo "$next" >"$index_file"
  echo "$speaker_id" >"$session_file"
  newly_assigned=1
fi

# --- ready announcement (first assignment only) ---------------------------
# Engine is remotely hosted — no local bootstrap needed.
if [ "$newly_assigned" = "1" ]; then
  sid=$(resolve_speaker "$session_id") && speak_text "$sid" "TTSを開始します。" "$session_id" >/dev/null 2>&1 || true
fi

jq -n --arg additionalContext "$instructions" \
  '{
    hookSpecificOutput: {
      hookEventName: "SessionStart",
      additionalContext: $additionalContext
    }
  }'

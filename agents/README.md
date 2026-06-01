# Agent Skills

このディレクトリはClaude Codeで使用するスキルを管理します。

## スキル管理

スキルは`agent-skills-nix`フレームワークで管理されています。

- **設定**: `nix/modules/home/coding-agents/agent-skills`
- **ローカルスキル**: `github:yutakobayashidev/skills` (別リポジトリ)
- **デプロイ先**:
  - `~/.agents/skills`
  - `~/.config/claude/skills`
  - `~/.config/codex/skills`
  - Hermes microVM: `/var/lib/hermes/.hermes/skills`
  - OpenClaw microVM: `/persist/openclaw/.openclaw/workspace/skills`

Hermes microVM 向けのスキルは `systems/nixos/services/hermes-agent/guest.nix` で個別に bundle 化し、シンボリックリンクではなく実体コピーで配置します。Hermes の agent-facing document は `systems/nixos/services/hermes-agent/documents/` を正本にします。
OpenClaw microVM は `systems/nixos/services/openclaw/guest.nix` で `nix-openclaw` の bundled plugins を宣言し、workspace documents は `systems/nixos/services/openclaw/documents/` を正本にします。

## スキルの追加

1. `skills/<skill-name>/`ディレクトリを作成 (https://github.com/yutakobayashidev/skills)
2. `SKILL.md`ファイルを作成
3. `nh os switch`で反映

## スキル一覧の見方

- ローカルスキルは https://github.com/yutakobayashidev/skills を見ればよい
- 有効化している外部スキルソースと明示スキルは `nix/modules/home/coding-agents/agent-skills` が正本
- 外部カタログ:
  - Anthropic: https://github.com/anthropics/skills
  - Vercel: https://github.com/vercel-labs/skills
  - Obsidian: https://github.com/kepano/obsidian-skills
  - Matt Pocock: https://github.com/mattpocock/skills
  - Superpowers: https://github.com/obra/superpowers

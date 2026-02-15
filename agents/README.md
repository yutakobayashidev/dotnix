# Agent Skills

このディレクトリはClaude Codeで使用するスキルを管理します。

## スキル管理

スキルは`agent-skills-nix`フレームワークで管理されています。

- **設定**: `nix/modules/home/agent-skills.nix`
- **ローカルスキル**: `agents/skills/`
- **デプロイ先**:
  - `~/.agents/skills`
  - `~/.config/claude/skills`

## スキルの追加

1. `agents/skills/<skill-name>/`ディレクトリを作成
2. `SKILL.md`ファイルを作成
3. `nh os switch`で反映

## 利用可能なスキル

### ローカルスキル

- `social-digest` - Discord + Mastodon投稿をObsidianに保存
- `oura-daily-watch` - Oura Ring データ + Discord行動分析

### Anthropic公式スキル

#### ドキュメントスキル
- `docx` - Word文書作成・編集
- `pdf` - PDF作成・抽出
- `pptx` - PowerPoint作成・編集
- `xlsx` - Excel処理

#### サンプルスキル
- `frontend-design` - フロントエンドデザイン
- `skill-creator` - スキル作成ガイド
- `webapp-testing` - Webアプリテスト（Playwright）

その他のAnthropicスキルは`nix/modules/home/agent-skills.nix`で追加可能です。
利用可能なスキル一覧: https://github.com/anthropics/skills

### Vercel公式スキル

- `find-skills` - スキル検索・発見支援

その他のVercelスキルは`nix/modules/home/agent-skills.nix`で追加可能です。
利用可能なスキル一覧: https://github.com/vercel-labs/skills

### コミュニティスキル

- `ui-ux-pro-max` - UI/UXデザインシステム生成（nextlevelbuilder）

# Grok Bot cloud environment

`homeConfigurations.grok-bot` manages the existing Grok Bot Linux user's tools
and dotfiles using standalone Home Manager. It reuses the Home Manager halves
of `base` and `development`, plus the shared CLI modules and `homes/common.nix`.
It does not provision the VM or change its operating system.

The reported guest is Debian 13 (trixie), x86_64, user `box` (uid 1000), with
passwordless sudo and `tini` as PID 1. Use single-user Nix, with `/nix` owned by
`box`; no Nix daemon or systemd user services are required.

## Configuration

- `modules/standalone.nix`: Home Manager output and existing package overlays.
- `homes/standalone/grok-bot/default.nix`: VM identity and profile selection.
- `scripts/bootstrap-grok-bot.sh`: initial installation, application, and recovery.

The configuration currently expects `/home/box`. Confirm `echo "$HOME"` in the
**cloud computer**, not the local desktop, before installing. If it differs,
update both the configuration and the bootstrap's preflight check. The script
refuses to activate on another user, home directory, architecture, or NixOS.

The development profile includes agent tools and skills. Desktop apps stay off.
The VM disables Codex desktop hooks/audio/transcription, Codex and Claude OTLP
telemetry, Atuin automatic sync, the private SearxNG MCP entry, and the OpenCode
LM Studio provider. Claude uses the direct Anthropic endpoint. Authentication
is still required for tools that use external accounts; no credentials or sops
keys are copied from existing hosts.

ACP clients can launch `codex-acp`, `claude-agent-acp`, and `pi-acp` over stdio.
The host enables `my.programs.codex.acp.enable`,
`my.programs.claude-code.acp.enable`, and `my.programs.pi.acp.enable`.
All three options default to disabled. These adapters use the existing pinned packages.
After applying the configuration in the VM and loading the session environment,
verify their availability with:

```sh
command -v codex-acp claude-agent-acp pi-acp
```

Configure those commands in the ACP client and authenticate each agent as
needed. Installing the adapters does not register them with Grok Bot automatically.

Skills are linked by Home Manager only into `~/.config/claude/skills`,
`~/.config/codex/skills`, and `~/.pi/agent/skills`. These fixed destinations do
not depend on the activation shell's `CLAUDE_CONFIG_DIR` or `CODEX_HOME`.
Recursive Home Manager links coexist with its generated Claude skill and
unmanaged skills; the tree synchronizer must not take over these directories.
Do not use `AGENT_SKILLS_FORCE=1` to recover from a skills ownership error.

Older revisions installed skills into additional destinations such as
`~/.claude/skills` and `~/.cursor/skills`. Updating does not delete those files;
review them separately before cleanup because the VM is shared. Limiting the
targets limits writes, not access: Bots sharing the `box` account can still
read one another's files.

If a second application failed at `agent-skills` on an older revision, update
the clean `main` checkout with `git pull --ff-only`, then run bootstrap twice
and run `--check`. No environment-variable unsetting, force takeover, or
deletion of existing skills is needed. Save the Bot's recovery skill only after
both applications succeed.

## First application

Make the reviewed dotnix revision available in the cloud computer. For an
already published revision, clone the repository there:

```sh
git clone https://github.com/yutakobayashidev/dotnix.git
cd dotnix
id
echo "$HOME"
bash scripts/bootstrap-grok-bot.sh
```

For an unpublished change, transfer the reviewed checkout first; cloning the
remote does not include local changes. Do not run the bootstrap with sudo.
Only the Nix installer's initial creation of `/nix` needs sudo.

The bootstrap verifies a pinned official Nix installer checksum, uses
`--no-daemon`, and builds the locked Home Manager activation package before
applying it. It accepts the binary caches and keys declared by this flake.
It does not update `flake.lock` or install Enterprise Team Setup Scripts.

The existing shared dotfile hooks replace Zsh and Neovim configuration directly.
Before activation, the bootstrap moves existing unmanaged `.zshenv`, `.zshrc`,
`.config/zsh`, and `.config/nvim` to a unique directory under
`~/.local/state/dotnix/backups/`. Keep these backups until the new environment
has been checked. Other Home Manager collisions use the `hm-bak` suffix;
an existing conflicting backup causes activation to stop rather than overwrite
it. The login shell remains unchanged; Zsh is available explicitly. Nix commands
and flakes are enabled in the managed user-level `nix.conf`.

In each noninteractive shell used by the Bot, load Nix before using tools:

```sh
. "$HOME/.nix-profile/etc/profile.d/nix.sh"
. "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
bash /path/to/dotnix/scripts/bootstrap-grok-bot.sh --check
```

The script's exports cannot modify its parent shell. New interactive Bash
sessions load the managed environment; a running Bot shell needs the explicit
source command above.

## Recovery and Bot instructions

[Official computer-management documentation](https://docs.x.ai/grok-bot/computers)
says recreating or terminating the computer preserves durable user data but
removes user-installed applications and packages. The exact persistence of
`/nix` has not been verified. Keep the checkout/configuration recoverable and
assume that Nix may need reinstalling.

Rerunning bootstrap reapplies the current checkout. If `/nix/store` still
exists but Nix cannot run, the script stops for diagnosis instead of deleting
the store. If `/nix` was lost, it installs Nix again and rebuilds the environment.
Do not deliberately reset the VM merely to test persistence.

## Copy-paste prompts for Grok Bot

These prompts are for the individual plan and do not require Team Setup
Scripts. Send the first prompt after the configuration has been pushed to
`main`. The second prompt can be saved as a Grok Bot skill for subsequent tasks;
this repository does not register that skill in the app automatically.

### Initial setup

```text
あなたのクラウドコンピューターに、dotnixで宣言したNix＋Home Manager環境を導入してください。
ローカルPCではなく、Grok BotのクラウドVM内で実行してください。

リポジトリ: https://github.com/yutakobayashidev/dotnix.git
配置先: /workspace/dotnix
対象: homeConfigurations.grok-bot

1. id、uname -m、echo "$HOME"、cat /etc/os-release、sudo -n idで環境を確認してください。
   既存ユーザーbox、x86_64 Linux、HOME=/home/box、パスワードなしsudoが前提です。
   条件が違えば設定を書き換えず、その結果を報告して停止してください。

2. /workspace/dotnixがなければ、上記リポジトリのmainをそこへcloneしてください。
   既にある場合はremote・branch・git statusを確認し、同じリポジトリのクリーンなmainなら
   git pull --ff-onlyで更新してください。未コミット変更や別ブランチがあれば上書きせず報告してください。
   docs/grok-bot.mdとscripts/bootstrap-grok-bot.shを読んでください。

3. /workspace/dotnixで次を実行してください。
   bash scripts/bootstrap-grok-bot.sh
   bootstrapによるsingle-user Nixの導入、既存設定のバックアップ、Home Managerの適用を許可します。
   スクリプト全体をsudoで実行せず、必要なsudoはインストーラーに任せてください。
   NixOSへの置き換え、nix-daemonの導入、/nixの削除、flake.lockの更新、VMのリセットはしないでください。
   ツールのログインや秘密情報の移送は今回の作業に含みません。

4. 作業に使うシェルで次を実行してください。
   . "$HOME/.nix-profile/etc/profile.d/nix.sh"
   . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
   bash /workspace/dotnix/scripts/bootstrap-grok-bot.sh --check
   zsh --version
   新しいBashセッションでもgit・jq・rg・zsh・home-managerが利用できることを確認してください。
   bootstrapをもう一度実行し、再適用が成功することも確認してください。

5. 適用したgit commit、各検証結果、バックアップ先、残ったエラーを報告してください。
   エラー時は直前のコマンドと秘密情報を除いたログを示し、手動インストールで設定を迂回しないでください。
   成功後、docs/grok-bot.mdの「作業前チェックと復旧」を今後の作業前に使うスキルとして保存してください。
   スキル登録ができない場合は、その旨と保存できた手順の場所を報告してください。
```

### 作業前チェックと復旧

```text
開発ツールを使う前に、クラウドVMで次を実行してください。
  bash /workspace/dotnix/scripts/bootstrap-grok-bot.sh --check

チェックが成功したら、作業シェルに環境変数を読み込んでから作業してください。
  . "$HOME/.nix-profile/etc/profile.d/nix.sh"
  . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
シェルを新しく作る場合も、必要に応じて同じ読み込みを行ってください。

チェックが失敗した場合、既存の/workspace/dotnixから次を実行して再適用してください。
  bash /workspace/dotnix/scripts/bootstrap-grok-bot.sh
成功後に上記2ファイルを読み込み、--checkを再実行してください。
復旧時にgit pullやflake.lockの更新はせず、現在のチェックアウトを使ってください。
リポジトリ自体が消えている場合は、その状況を報告して初回導入手順に戻ってください。

/nixが残っているのにNixが動かないなど、bootstrapが停止した場合はエラーを報告してください。
/nixの削除、ユーザー変更、nix-daemonの導入、VMリセットによる修復はしないでください。
復旧できていない状態で、環境が利用可能と報告しないでください。
```

## Verification

From the repository root, evaluate the real configuration and build without
activating anything on the local host:

```sh
nix eval --json --impure --expr 'let f = builtins.getFlake ("path:" + toString ./.); in import ./tests/grok-bot.nix { configuration = f.homeConfigurations.grok-bot; }'
nix build --no-link --impure --expr 'let f = builtins.getFlake ("path:" + toString ./.); in import ./tests/grok-bot-skills.nix { configuration = f.homeConfigurations.grok-bot; }'
nix build path:.#homeConfigurations.grok-bot.activationPackage --no-link
bash tests/bootstrap-grok-bot.sh
```

The skills regression test runs the real Home Manager file-linking phases in
a temporary home twice, without and with agent session variables. It verifies
that the generated Claude skill and unrelated files survive. The shell tests
mock installation/build boundaries and never install Nix or activate Home Manager.
A successful local build does not prove deployment in
the hosted VM. After applying there, run `--check`, open a fresh shell, verify
`git`, `jq`, `rg`, `zsh`, and `home-manager`, and run bootstrap again to verify
reapplication. Retain the resulting errors or success output for diagnosis.

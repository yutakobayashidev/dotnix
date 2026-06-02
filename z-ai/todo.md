# B450M SOPS Key Rotation

- [x] Confirm old B450M age key is unrecoverable from local logs/tmp.
- [x] Generate a new B450M age key outside the repo and outside tmp.
- [x] Replace the B450M recipient in `.sops.yaml`.
- [x] Re-key shared secrets that are decryptable from this Mac.
- [x] Recreate B450M-only secrets with fresh values or known replacement values.
- [x] Add durable agent instructions against writing secrets to tmp.
- [x] Update lessons with the tmp-secret failure pattern.
- [x] Verify sops metadata and Nix formatting/evaluation enough for this change.
- [x] Record review notes.

## Plan

Rotate the lost B450M age recipient by generating a new persistent age identity at a repo-external path, updating `.sops.yaml`, and re-encrypting affected files. Files encrypted only to the lost B450M recipient cannot be decrypted, so recreate those secrets instead of trying to recover them.

## Review

### Verification Results

- **sops metadata**: 全ファイルが新しいB450M recipient (`age1ahvwx3a7z...h23jle`) で暗号化されていることを確認。
  - `secrets/default.yaml`: UM790 + B450M-new + M2-MacBook-Air の3recipient ✓
  - `systems/nixos/services/grafana/secrets.yaml`: B450M-new のみ ✓
  - `systems/nixos/services/nextcloud/secrets/default.yaml`: B450M-new のみ ✓
  - `systems/nixos/services/oura-metrics/secrets.yaml`: B450M-new のみ ✓
- **復号確認**: `secrets/default.yaml` は Mac の age 鍵で復号可能。B450M-only の3ファイルは Mac から復号不可（正しい動作）。
- **nix eval**: `B450M-Pro4` の評価成功 (`/nix/store/3dh1h58x...-nixos-system-B450M-Pro4-26.05.20260521.a81eafb.drv`)。
- **nix fmt**: フォーマット変更なし（0 changed）。

### nix-anywhere 時の注意点

- `sops.age.generateKey = true` により、`keyFile` が存在しない場合ランダムな鍵が自動生成される。これは `.sops.yaml` の recipient と一致しないため、全 secrets 復号が失敗する。
- `sshKeyPaths` は SSH ホスト鍵から age 鍵を派生させるが、この SSH 鍵の age 公開鍵は `.sops.yaml` に登録されていないためフォールバックとして機能しない。
- **対策**: `nix-anywhere` 前に `b450m-pro4.keys.txt` をターゲットの `/home/yuta/.config/sops/age/keys.txt` に配置する手順を `docs/B450M-Pro4.md` に追加した。

### 変更ファイル一覧

| ファイル                                                | 変更内容                                                    |
| ------------------------------------------------------- | ----------------------------------------------------------- |
| `.sops.yaml`                                            | B450M recipient を新鍵に差し替え                            |
| `secrets/default.yaml`                                  | 3 recipient で再暗号化                                      |
| `systems/nixos/services/grafana/secrets.yaml`           | B450M 新鍵で再暗号化（値は再生成）                          |
| `systems/nixos/services/nextcloud/secrets/default.yaml` | B450M 新鍵で再暗号化（値は再生成）                          |
| `systems/nixos/services/oura-metrics/secrets.yaml`      | B450M 新鍵で再暗号化（値は再入力）                          |
| `AGENTS.md`                                             | Secret Handling セクション追加（tmpに秘密鍵を書かない指示） |
| `docs/B450M-Pro4.md`                                    | nix-anywhere 前に age 鍵配置手順を追加                      |
| `z-ai/lessons.md`                                       | tmp-secret failure pattern を記録                           |

# Twitter API Safe Relay Skill

- [x] Confirm the upstream skill layout and existing `agent-skills-nix` pattern.
- [x] Add the upstream GitHub flake input.
- [x] Enable the upstream `twitter-api-replay` skill through `agent-skills-nix`.
- [x] Update the external skill source documentation.
- [x] Update `flake.lock`.
- [x] Run formatting and Nix evaluation checks.
- [x] Record review notes.

## Plan

Add `fa0311/twitter_api_safe_relay_skills` as a non-flake input and enable its `skills/` directory through the existing Home Manager `agent-skills-nix` module.

## Review

- Upstream layout: confirmed `skills/twitter-api-replay/` is the source of truth.
- `flake.lock`: pinned `fa0311/twitter_api_safe_relay_skills` at `19f55e7e81fe588ed47554afa8b2419775335604`.
- `nix fmt`: completed with `0 changed`.
- `git diff --check`: completed without errors.
- `nix eval --json '.#darwinConfigurations.M2-MacBook-Air.config.home-manager.users.yuta.programs.agent-skills.skills.enableAll'`: includes `twitter-api-safe-relay`.
- `nix eval --raw '.#darwinConfigurations.M2-MacBook-Air.config.system.build.toplevel.drvPath'`: succeeded with `/nix/store/39idl965lsig8cx9gicww00byhzjj6qp-darwin-system-26.05.56c666e.drv`.

# Homebrew Cleanup Activation Fix

- [x] Confirm the generated Homebrew activation command fails because cleanup lacks explicit confirmation.
- [x] Check the nix-darwin Homebrew activation options for a native flag hook.
- [x] Add the narrow `--force-cleanup` flag to Homebrew activation.
- [x] Evaluate the generated activation command.
- [x] Run formatting and diff checks.
- [x] Record review notes.

## Plan

Keep `cleanup = "uninstall"` and pass Homebrew's `--force-cleanup` flag through
`homebrew.onActivation.extraFlags`. This preserves declarative cleanup without
using the broader `--force` behavior.

## Review

- `nix eval --json '.#darwinConfigurations.M2-MacBook-Air.config.homebrew.onActivation.extraFlags'`: returned `["--force-cleanup"]`.
- `nix eval --raw '.#darwinConfigurations.M2-MacBook-Air.config.system.activationScripts.homebrew.text'`: generated `brew bundle ... --cleanup --force-cleanup`.
- `nix fmt`: completed with `0 changed`.
- `git diff --check`: completed without errors.
- Documentation check: no updates needed for `README.md`, `AGENTS.md`, `CLAUDE.md`, or `docs/`; this only adjusts an existing Homebrew activation flag.

# Home Manager And Stable Nixpkgs Upgrade

- [x] Confirm the root Home Manager input and current lock state.
- [x] Update the root `home-manager` flake input.
- [x] Update the root `nixpkgs-stable` flake input.
- [x] Evaluate the affected Home Manager-backed configuration and confirm the release mismatch warning is gone.
- [x] Run diff checks and record review notes.

## Plan

Update the root `home-manager` and `nixpkgs-stable` lock nodes while preserving
their existing input definitions. Verify with a Darwin configuration
evaluation, then inspect the lock diff and document whether user-facing docs
need changes.

## Review

- `home-manager`: updated from `61e2c9659324181e0f0ed911958c536333b1d4f6`
  to `7d8127d308c3fb9664f7e643eec944be74ebb37d`.
- `nixpkgs-stable`: update command completed without a lock diff because the
  existing revision `25f538306313eae3927264466c70d7001dcea1df` was already current.
- `nix eval --raw '.#darwinConfigurations.M2-MacBook-Air.config.system.build.toplevel.drvPath'`:
  succeeded with `/nix/store/w6prrdxlnp4q55d7ih4s1kpi6z91avxk-darwin-system-26.05.56c666e.drv`.
  The Home Manager release mismatch warning is gone.
- `git diff --check`: completed without errors.
- Documentation check: no updates needed for `README.md`, `AGENTS.md`,
  `CLAUDE.md`, or `docs/`; this only refreshes the Home Manager lock revision.

# Nixpkgs Stable 26.05 Upgrade

- [x] Confirm the official `nixos-26.05` branch exists upstream.
- [x] Change the root `nixpkgs-stable` input from `nixos-25.11` to `nixos-26.05`.
- [x] Refresh the root `nixpkgs-stable` lock node.
- [x] Evaluate the Darwin configuration and run diff checks.
- [x] Review documentation impact and record results.

## Plan

Move the stable fallback input to the official Nixpkgs `nixos-26.05` release
branch, refresh only that lock node, and evaluate the Darwin configuration.
Keep existing `stateVersion` declarations unchanged because they are migration
compatibility settings, not package channel selectors.

## Review

- Official upstream check: `refs/heads/nixos-26.05` exists at
  `b51242d7d43689db2f3be91bd05d5b24fbb469c4`.
- `nixpkgs-stable`: moved from the `nixos-25.11` branch at `25f5383...` to the
  `nixos-26.05` branch at `b51242d...`.
- `nix eval --raw '.#darwinConfigurations.M2-MacBook-Air.config.system.build.toplevel.drvPath'`:
  succeeded with `/nix/store/ippq71jxdl1pqbai0m1ina6822iphkvn-darwin-system-26.05.56c666e.drv`.
- `nix fmt`: completed with `0 changed`.
- `git diff --check`: completed without errors.
- Documentation check: no updates needed for `README.md`, `AGENTS.md`,
  `CLAUDE.md`, or `docs/`; the stable fallback architecture and commands are
  unchanged.

# Darwin Tailscale DNS Fix

- [x] Confirm the rebuild failure is caused by DNS resolution rather than MAS app IDs.
- [x] Inspect nix-darwin's Tailscale DNS behavior and the active macOS resolver state.
- [x] Remove the fragile global Tailscale DNS override while preserving MagicDNS.
- [x] Configure B450M-Pro4 to use only its local CoreDNS resolver.
- [x] Evaluate the affected configurations and run diff checks.
- [x] Review documentation impact and record results.

## Plan

Remove `services.tailscale.overrideLocalDns = true` from the Darwin common
configuration. The nix-darwin Tailscale module already installs a split DNS
resolver for `ts.net`, so normal Wi-Fi DNS can handle public domains without
giving up MagicDNS. Configure B450M-Pro4 to use only `127.0.0.1` so CoreDNS is
the single resolver and DNS routing failures are visible instead of silently
bypassed.

## Review

- Darwin `networking.dns`: evaluates to `[]`, restoring DHCP-provided DNS.
- Darwin `environment.etc."resolver/ts.net".text`: remains
  `nameserver 100.100.100.100`, preserving MagicDNS split DNS.
- B450M-Pro4 `networking.nameservers`: evaluates to `["127.0.0.1"]`.
- Darwin toplevel evaluation: succeeded with
  `/nix/store/aniq3cgzddhz2xmf5r62ay714c3xpddw-darwin-system-26.05.56c666e.drv`.
- B450M-Pro4 toplevel evaluation: succeeded with
  `/nix/store/2840bh1gbjfw7gknbb0daw5sam912zvv-nixos-system-B450M-Pro4-26.11.20260529.e9a7635.drv`.
- `nix fmt`: completed with `0 changed`.
- `git diff --check`: completed without errors.
- Documentation check: no updates needed for `README.md`, `AGENTS.md`,
  `CLAUDE.md`, or `docs/`; existing commands and architecture are unchanged.

# Darwin MAS Activation Workaround

- [x] Confirm the Homebrew Bundle failure matches the upstream nix-homebrew issue.
- [x] Disable Homebrew auto-update during nix-darwin activation.
- [x] Link the upstream issue next to the workaround.
- [x] Restore Spotlight indexing for the macOS Data volume.
- [x] Confirm `mas list` detects Keynote, Numbers, and Pages again.
- [ ] Evaluate the generated Homebrew activation script and run diff checks.
- [ ] Review documentation impact and record results.

## Plan

Apply the upstream workaround from
https://github.com/zhaofengli/nix-homebrew/issues/131 by disabling Homebrew
auto-update during nix-darwin activation. Keep normal manual Homebrew updates
unchanged. Restore the disabled Spotlight index on the macOS Data volume so
`mas` can detect already installed App Store applications.

## Review

- Pending final verification.

# Codex Session TTS Plugin Detail Fix

- [x] Reproduce the personal marketplace plugin path mismatch.
- [x] Validate the existing plugin against the current Codex plugin contract.
- [x] Move the plugin symlink to the personal marketplace source path.
- [x] Update the marketplace source descriptor and plugin metadata.
- [x] Move the internal say adapter out of the public skills directory.
- [ ] Validate the plugin and reinstall it through Home Manager.
- [ ] Confirm Codex can read plugin details and record review notes.

## Plan

Align `session-tts` with the current personal marketplace layout:
`~/.agents/plugins/marketplace.json` points to `./plugins/session-tts`, which
resolves to `~/plugins/session-tts`. Keep hook discovery under `hooks/`, expose
only real skills under `skills/`, then validate and reinstall the local plugin.

## Review

- Pending final verification.

# Codex Session TTS Thread ID Fix

- [x] Reproduce the missing session identifier error from the TTS skill.
- [x] Inspect the Bash tool environment for the identifier Codex exposes.
- [x] Replace the incorrect `CODEX_SESSION_ID` references with `CODEX_THREAD_ID`.
- [x] Verify session-local `status`, `off`, and `on` behavior.
- [x] Run diff checks and review documentation impact.

## Plan

Use Codex's exported `CODEX_THREAD_ID` for Bash tool calls. Hook payloads keep
using their JSON `session_id` field because Codex supplies that identifier on
stdin for hook invocations.

## Review

- Root cause: Bash tool calls export `CODEX_THREAD_ID`, not
  `CODEX_SESSION_ID`. Hook payloads still provide JSON `session_id`.
- Updated `skills/tts/tts.sh`, `scripts/say.sh`, and the TTS skill
  documentation to use `CODEX_THREAD_ID`.
- Reinstalled `session-tts@personal` with `codex plugin remove` followed by
  `codex plugin add`, refreshing the user cache.
- Cached skill verification: `Codex TTS (this session): ON`.
- Shell adapter verification: simulated `SessionStart`, then confirmed
  `status`, `off`, `status`, `on`, `status`, and `say.sh` behavior.
- `bash -n`, `git diff --check`, and `git diff --cached --check`: passed.
- Darwin toplevel evaluation: succeeded with
  `/nix/store/cm15rvb0ifpblnpmk18b5z7qd8lagl47-darwin-system-26.05.56c666e.drv`.
- Python suite: `50 passed, 5 failed`. The existing chunking failures are
  unrelated to this shell adapter fix.
- Documentation check: no updates needed for `README.md`, `AGENTS.md`,
  `CLAUDE.md`, or `docs/`; the affected TTS skill documentation was updated.

# Codex Session TTS Chunking Fix

- [x] Reproduce the five Python chunking test failures.
- [x] Identify sentence recombination and whitespace removal as the causes.
- [x] Keep sentence chunks separate unless a single sentence needs forced splitting.
- [x] Preserve paragraph separators while ignoring whitespace-only input.
- [x] Run the Python suite and diff checks.
- [x] Evaluate the Darwin configuration and record final results.

## Plan

Keep `_split_paragraph()` focused on sentence boundaries and forced splitting
of oversized sentences. Preserve paragraph separators in `split_into_chunks()`
so concatenating chunks reconstructs the cleaned input.

## Review

- Root cause: `_split_paragraph()` split on sentence punctuation and then
  recombined adjacent sentences whenever they fit under the size limit. Its
  regex also discarded whitespace after punctuation, while
  `split_into_chunks()` discarded paragraph separators with `strip()`.
- `_split_paragraph()` now returns sentence chunks directly and only invokes
  `_force_split()` for an oversized sentence.
- `split_into_chunks()` now carries paragraph separators into the following
  paragraph while still ignoring whitespace-only input.
- Python suite: `55 passed`.
- `bash -n`, `git diff --check`, and `git diff --cached --check`: passed.
- Darwin toplevel evaluation: succeeded with
  `/nix/store/21cw3hy7r1xplh40f15z97hg4p0s76ab-darwin-system-26.05.56c666e.drv`.
- Documentation check: no updates needed for `README.md`, `AGENTS.md`,
  `CLAUDE.md`, or `docs/`; this is an internal chunking behavior correction.

---
name: gha-lint
description: Lint and secure GitHub Actions workflows using pinact, actionlint, ghalint, and zizmor. Use when the user adds, updates, or reviews GitHub Actions workflows and wants to check correctness, security, or pin action versions.
user-invocable: true
---

# GitHub Actions Lint & Security

Static analysis and security checking tools for GitHub Actions workflows. All tools are available via nixpkgs for local use. Each tool covers different checks with no overlap, so using all of them together is recommended.

| Tool | Purpose | nixpkgs |
|------|---------|---------|
| **actionlint** | Workflow syntax checking | `nixpkgs#actionlint` |
| **pinact** | SHA-pin action references | `nixpkgs#pinact` |
| **ghalint** | Security best practices | `nixpkgs#ghalint` |
| **zizmor** | Security vulnerability analysis | `nixpkgs#zizmor` |

---

## actionlint

Syntax and type checker for workflow files. Integrates with shellcheck / pyflakes to also inspect inline scripts.

### Basic Commands

```bash
# Auto-detect and check all files under .github/workflows/
nix run nixpkgs#actionlint

# Check a specific file
nix run nixpkgs#actionlint -- .github/workflows/nix-build.yaml

# JSON output
nix run nixpkgs#actionlint -- -format '{{json .}}'
```

### What It Detects

- Workflow syntax errors (missing required keys, duplicate keys, invalid values)
- Type checking of `${{ }}` expressions (undefined context references, etc.)
- Shell script issues via shellcheck
- Python script issues via pyflakes
- Matrix inconsistencies, invalid glob patterns
- Deprecated commands (`set-output`, etc.)

### CI Usage

Use `suzuki-shunsuke/actionlint-action` (installs actionlint + reviewdog + shellcheck via aqua):

```yaml
      - uses: suzuki-shunsuke/actionlint-action@29e0b7cda52e51a495d15f22759745ef6e19583a # v0.1.1
```

Or use the official download script:

```yaml
      - name: Install actionlint
        run: bash <(curl https://raw.githubusercontent.com/rhysd/actionlint/main/scripts/download-actionlint.bash)
      - name: actionlint
        run: ./actionlint
```

---

## pinact

Converts GitHub Actions version references to commit SHAs. Prevents supply chain attacks via tag rewriting.

### Configuration

Place `.pinact.yml` at the repository root:

```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/suzuki-shunsuke/pinact/refs/heads/main/json-schema/pinact.json
version: 3
```

Initialize: `nix run nixpkgs#pinact -- init`

### Basic Commands

```bash
# Pin all actions under .github/workflows/
nix run nixpkgs#pinact -- run

# Include composite actions etc.
nix run nixpkgs#pinact -- run \
  .github/actions/setup-nix/action.yaml \
  .github/actions/setup-git-bot/action.yaml

# Validate only (no file changes, good for CI)
nix run nixpkgs#pinact -- run --check

# Show diff only
nix run nixpkgs#pinact -- run --diff

# Update to latest versions
nix run nixpkgs#pinact -- run --update
```

### Conversion Format

```yaml
# Before
- uses: actions/checkout@v4

# After
- uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v4.3.1
```

- Tags are replaced with SHAs; the original version is appended as a comment
- Files outside `.github/workflows/` (composite actions, etc.) must be specified explicitly

### Key Options

| Option | Description |
|--------|-------------|
| `--check` | Non-zero exit if unpinned references exist. No file changes |
| `--verify, -v` | Verify SHA and version annotation consistency |
| `--update, -u` | Update to latest versions |
| `--diff` | Output diff only. No file changes |
| `--include, -i` | Filter targets by regex |
| `--exclude, -e` | Exclude targets by regex |
| `--min-age, -m` | Skip releases newer than N days (use with `-u`) |

### CI Usage

Use `suzuki-shunsuke/pinact-action`:

```yaml
      - uses: suzuki-shunsuke/pinact-action@1081f5ad49ac904b7d977784f338145150a32112 # v1.4.0
        with:
          skip_push: "true"
```

---

## ghalint

Linter for security best practices in workflow and action definitions.

### Basic Commands

```bash
# Check workflows
nix run nixpkgs#ghalint -- run

# Check action definitions
nix run nixpkgs#ghalint -- run-action
```

### What It Detects

- Jobs missing explicit `permissions`
- Action references not pinned to commit SHAs
- `actions/checkout` without `persist-credentials: false`
- Other security best practice violations

### CI Usage

Install via aqua:

```yaml
      - uses: aquaproj/aqua-installer@11dd79b4e498d471a9385aa9fb7f62bb5f52a73c # v4.0.4
        with:
          aqua_version: v2.56.6
      - run: ghalint run
        env:
          GHALINT_LOG_COLOR: always
```

Requires `aqua.yaml` in the repository with ghalint registered:

```yaml
# aqua.yaml
registries:
  - type: standard
    ref: v4.294.0
packages:
  - name: suzuki-shunsuke/ghalint@v1.5.5
```

---

## zizmor

Security vulnerability analyzer for GitHub Actions. Offers 3 personas to tune detection sensitivity.

### Basic Commands

```bash
# Analyze current repository (auto-detects .github/)
nix run nixpkgs#zizmor -- .

# Check a specific file
nix run nixpkgs#zizmor -- .github/workflows/nix-build.yaml

# Pedantic mode (also detects code smells)
nix run nixpkgs#zizmor -- --pedantic .

# Offline mode (no GitHub API needed)
nix run nixpkgs#zizmor -- --offline .

# SARIF output
nix run nixpkgs#zizmor -- --format sarif .
```

### Personas (Detection Sensitivity)

| Persona | Description |
|---------|-------------|
| `regular` (default) | Minimizes false positives |
| `pedantic` | Also detects code smells |
| `auditor` | Comprehensive detection, tolerates false positives |

### What It Detects

- Excessive `permissions` settings
- Code injection via template expansion (`${{ }}`)
- Direct use of untrusted inputs
- Potential commit spoofing
- Dangerous use of `pull_request_target`
- Improper use of self-hosted runners

### CI Usage

Use `zizmorcore/zizmor-action`:

```yaml
      - uses: zizmorcore/zizmor-action@0dce2577a4760a2749d8cfb7a84b7d5585ebcb7d # v0.5.0
```

With GitHub Advanced Security:

```yaml
      - uses: zizmorcore/zizmor-action@0dce2577a4760a2749d8cfb7a84b7d5585ebcb7d # v0.5.0
```

Without Advanced Security:

```yaml
      - uses: zizmorcore/zizmor-action@0dce2577a4760a2749d8cfb7a84b7d5585ebcb7d # v0.5.0
        with:
          advanced-security: false
```

---

## CI Integration: All Tools Combined

Example workflow combining all 4 tools using their official actions (no nixpkgs):

```yaml
name: "CI: GitHub Actions lint"

on:
  pull_request:
  workflow_dispatch:

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

permissions: {}

jobs:
  gha-lint:
    runs-on: ubuntu-24.04-arm
    timeout-minutes: 10
    permissions:
      contents: read
      actions: read
    steps:
      - uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2
        with:
          persist-credentials: false

      - name: actionlint
        run: |
          bash <(curl https://raw.githubusercontent.com/rhysd/actionlint/main/scripts/download-actionlint.bash)
          ./actionlint

      - uses: suzuki-shunsuke/pinact-action@1081f5ad49ac904b7d977784f338145150a32112 # v1.4.0
        with:
          skip_push: "true"

      - uses: aquaproj/aqua-installer@11dd79b4e498d471a9385aa9fb7f62bb5f52a73c # v4.0.4
        with:
          aqua_version: v2.56.6
      - name: ghalint
        run: ghalint run
        env:
          GHALINT_LOG_COLOR: always

      - uses: zizmorcore/zizmor-action@0dce2577a4760a2749d8cfb7a84b7d5585ebcb7d # v0.5.0
        with:
          advanced-security: false
```

---

## Workflow: When Adding or Modifying GitHub Actions

1. Edit workflows or composite actions
2. Run all tools locally:

```bash
nix run nixpkgs#actionlint
nix run nixpkgs#pinact -- run
nix run nixpkgs#ghalint -- run
nix run nixpkgs#zizmor -- .
```

3. Review changes and commit:

```bash
git diff
```

4. Open a PR and verify CI passes

## Notes

- Setting `GITHUB_TOKEN` / `GH_TOKEN` avoids API rate limits (pinact, zizmor)
- actionlint auto-integrates with shellcheck and pyflakes if they're in PATH (nixpkgs version bundles them)
- ghalint's checks partially overlap with pinact (SHA pinning), but ghalint also covers other best practices, so using both is worthwhile

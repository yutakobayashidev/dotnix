---
paths:
  - "~/ghq/github.com/yutakobayashidev/**"
---

# Commit Message Convention

Follow [Conventional Commits](https://www.conventionalcommits.org/) with **required scope**.

Format: `<type>(<scope>): <description>`

## Types

- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation changes
- `build` - Build system, dependencies, Nix flake
- `chore` - Maintenance tasks
- `ci` - CI/CD configuration
- `refactor` - Code restructuring without behavior change
- `test` - Adding or updating tests
- `perf` - Performance improvements
- `style` - Code style (formatting, semicolons, etc.)
- `revert` - Reverting a previous commit

## Scope

Scope is **mandatory**. Use the most relevant area for the project. Each project's CLAUDE.md lists its available scopes.

## PR Titles

PR titles **must** follow the same convention. Squash merges use the PR title as the commit message.

## Bad Examples

```
feat: add markdown output        # missing scope
update code                      # missing type and scope
fix(github): Fix bug.            # don't capitalize, don't end with period
Core: CLI + GitHub プロバイダー  # PR title not following convention
```

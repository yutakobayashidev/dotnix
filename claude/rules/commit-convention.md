---
paths:
  - '~/ghq/github.com/yutakobayashidev/**'
---

# Commit Message Convention

Follow [Conventional Commits](https://www.conventionalcommits.org/).

Format: `<type>[optional scope]: <description>`

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

Scope is optional. When used, choose the most relevant area for the project.

## PR Titles

PR titles **must** follow the same convention. Squash merges use the PR title as the commit message.

## Bad Examples

```
update code                      # missing type and scope
fix(github): Fix bug.            # don't capitalize, don't end with period
Core: CLI + GitHub プロバイダー  # PR title not following convention
```

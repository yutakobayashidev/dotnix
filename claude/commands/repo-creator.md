Create a new repository with full scaffolding. Follow these steps exactly:

## 1. Ask Project Details

Use AskUserQuestion to gather all info in one prompt:

```
New repository setup:

1. Project name? (e.g. my-app)
2. Toolchain? Pick from: bun, c, c-cpp, clojure, cpp, cue, dhall, elixir, elm, gleam, go, hashi, haskell, java, jupyter, kotlin, latex, lean4, nickel, nim, nix, node, ocaml, odin, opa, php, platformio, protobuf, pulumi, purescript, python, r, ruby, rust, scala, shell, swi-prolog, swift, typst, vlang, zig
3. License? (mit, apache-2.0, gpl-3.0, unlicense, etc. Default: mit)
4. Visibility? (public / private. Default: public)
5. Description? (one-liner, optional)
```

## 2. Add Repository to OpenTofu

Add `github_repository` resource to `~/ghq/github.com/yutakobayashidev/homelab/tofu/github/repositories.tf`:

```hcl
resource "github_repository" "<project_name>" {
  name        = "<project_name>"
  description = "<description>"  # omit if empty
  visibility  = "<visibility>"

  has_issues    = true
  has_projects  = true
  has_wiki      = true
  has_downloads = true

  allow_merge_commit = true
  allow_squash_merge = true
  allow_rebase_merge = true

  delete_branch_on_merge = true

  license_template    = "<license>"           # e.g. "mit"
  gitignore_template  = "<Gitignore_template>" # e.g. "Go", "Rust", "Python", "Node" — omit if no match
}
```

Notes:

- Resource name: use the project name with hyphens converted to underscores
- Map the toolchain to the closest GitHub gitignore template name (e.g. go→Go, rust→Rust, python→Python, node→Node). If no match, omit `gitignore_template`.
- If description is empty, omit `description`.

## 3. Apply OpenTofu

```bash
cd ~/ghq/github.com/yutakobayashidev/homelab/tofu/github
tofu apply
```

## 4. Clone via ghq

```bash
ghq get yutakobayashidev/<project_name>
cd $(ghq root)/github.com/yutakobayashidev/<project_name>
```

Pull the generated LICENSE and .gitignore:

```bash
git pull origin main
```

## 5. Init Nix Flake from dev-templates

```bash
nix flake init -t github:the-nix-way/dev-templates#<toolchain>
```

## 6. Initial Commit

Stage all files and create an initial commit:

```bash
git add -A
git commit -m "feat: init <project_name> with <toolchain> flake"
git push -u origin main
```

## 7. Commit OpenTofu Changes

Back in the homelab repo, commit the new repository resource:

```bash
cd ~/ghq/github.com/yutakobayashidev/homelab
git add tofu/github/repositories.tf
git commit -m "feat: add <project_name> repository to OpenTofu"
git push
```

## 8. Summary

Print the final result:

- Repository URL
- Local path
- Toolchain and license used

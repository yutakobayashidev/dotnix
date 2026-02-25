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

## 2. Create Repository via ghq

```bash
ghq create <project_name>
```

Then `cd` into the created directory (under ghq root).

## 3. Init Nix Flake from dev-templates

```bash
nix flake init -t github:the-nix-way/dev-templates#<toolchain>
```

## 4. Create GitHub Remote

```bash
gh repo create <project_name> \
  --source . \
  --<visibility> \
  --license <license> \
  --gitignore <Gitignore_template> \
  --description "<description>"
```

Notes:
- Map the toolchain to the closest GitHub gitignore template name (e.g. go→Go, rust→Rust, python→Python, node→Node). If no match, omit `--gitignore`.
- If description is empty, omit `--description`.
- Pull the generated LICENSE and .gitignore from remote: `git pull --rebase origin main`

## 5. Initial Commit

Stage all files and create an initial commit:

```bash
git add -A
git commit -m "feat: init <project_name> with <toolchain> flake"
git push -u origin main
```

## 6. Summary

Print the final result:
- Repository URL
- Local path
- Toolchain and license used

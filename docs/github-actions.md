# GitHub Actions dependency checks

`.github/workflows/pinact.yaml` runs Pinact and pilots GitHub's workflow
lockfile support. `.github/workflows/actions.lock` currently covers only this
workflow. Other workflows continue to use their existing SHA pins.

Install the official extension and verify the pilot:

```bash
gh extension install github/gh-actions-lock --pin v0.4.0
gh actions-lock --verify .github/workflows/pinact.yaml
```

For an offline coverage check, use `--verify-local`; this does not verify
upstream provenance. Run the online `--verify` check before merging.

After changing the pilot's action dependencies, regenerate its lockfile:

```bash
gh actions-lock .github/workflows/pinact.yaml
```

The generator rewrites recognized SHA references as version tags. Keep the
existing SHA-pinning policy: restore the corresponding exact SHA references
and version comments in the workflow, then rerun `--verify`. Both SHA pins
and lockfile coverage are checked in CI. Review changed commits in the
lockfile before merging. Repository-wide lockfile enforcement is not enabled
by this pilot.

The extension and lockfile format are maintained by GitHub:
https://github.com/github/gh-actions-lock

In-repository actions and reusable workflows use `$/` references, which GitHub
resolves from the workflow's own commit rather than a runner checkout. This
also keeps the infrastructure deployment setup action on the trusted workflow
revision when a separately approved PR revision is checked out.

Zizmor 1.30.1 validates these references. Actionlint 1.7.12 does not yet support
this syntax ([upstream issue](https://github.com/rhysd/actionlint/issues/732)), so
`.github/actionlint.yaml` excludes only the missing-ref diagnostics for the
specific self-repository paths used here. Remove those exceptions once
Actionlint supports `$/`; other syntax and script checks remain enabled.

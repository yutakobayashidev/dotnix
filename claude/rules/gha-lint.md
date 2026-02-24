---
paths:
  - ".github/workflows/**"
  - ".github/actions/**"
---

# GitHub Actions Lint Requirement

When creating or modifying GitHub Actions workflows, **always** run the `gha-lint` skill (`/gha-lint`) before committing.

This runs 4 tools that cover different checks with no overlap:

1. **actionlint** — syntax and type checking
2. **pinact** — SHA-pin action references (supply chain security)
3. **ghalint** — security best practices (timeout, persist-credentials, etc.)
4. **zizmor** — security vulnerability analysis

All findings must be resolved before the workflow is committed.

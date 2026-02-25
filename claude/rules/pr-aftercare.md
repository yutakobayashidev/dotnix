# PR Aftercare

Workflow for CI monitoring and review handling after creating a PR.

## 1. CI Watch

Immediately after PR creation, wait for CI to complete and check results.

```bash
gh pr checks <PR_NUMBER> --watch --fail-fast
```

- **All pass** → proceed to the next step
- **Failure** → read logs, identify the cause, and fix. Commit & push, then watch again. Loop until green.

Keep fixes to minimal diffs. Do not mix in unrelated changes just to pass CI.

## 2. Review Triage

When asked to check review comments:

```bash
# Fetch review threads
gh api graphql -f query='
{
  repository(owner: "<OWNER>", name: "<REPO>") {
    pullRequest(number: <NUMBER>) {
      reviewThreads(first: 50) {
        nodes {
          id
          isResolved
          comments(first: 5) {
            nodes { body author { login } }
          }
        }
      }
    }
  }
}'
```

Classify each comment by the following criteria:

| Category | Criteria | Action |
|----------|----------|--------|
| **Fix immediately** | Can be addressed in code, no spec impact | Fix and commit |
| **Spec trade-off** | Fix would conflict with spec, or involves performance/complexity trade-offs | Summarize trade-offs and AskUserQuestion |
| **Incorrect feedback** | Reviewer misunderstanding or already addressed | Explain in a comment |

### Default to "fix"

When in doubt, just fix it. Debating low-cost fixes is a waste of time.

### When spec compromise is needed

Use the following format for AskUserQuestion:

```
Review comment: [summary of the feedback]

Options:
A) [fix description] — [pros] / [cons (spec change, perf impact, etc.)]
B) [alternative] — [pros] / [cons]
C) [keep as-is] — [reason]

Recommendation: [recommended option and rationale]
```

## 3. Resolve

After committing & pushing fixes, resolve the addressed review threads.

```bash
gh api graphql -f query='
mutation {
  resolveReviewThread(input: {threadId: "<THREAD_ID>"}) {
    thread { isResolved }
  }
}'
```

For multiple threads, batch them in a single mutation using aliases: `t1: resolveReviewThread(...)` `t2: resolveReviewThread(...)`.

**Before resolving, ensure:**
- Tests pass (`go test ./...` / `npm test` etc.)
- Lint passes
- Changes are pushed

## 4. Overall Flow

```
PR created
  └→ CI watch (fail → fix → push → re-watch)
      └→ CI green
          └→ Awaiting review
              └→ Review check requested
                  ├→ Fix immediately → commit & push → resolve
                  ├→ Spec trade-off → AskUser → fix or update spec per decision → resolve
                  └→ Incorrect feedback → explain in comment → resolve
                      └→ CI re-watch (fail → fix loop)
```

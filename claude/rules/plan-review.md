# Plan Review Rules

- Before presenting a plan to the user, review it using the codex command.
- Adjust the review prompt as needed. However, codex tends to nitpick trivial things, so always include: "No nitpicks. Only flag critical issues."
- Iterate update → review until codex raises no more issues.

```bash
# initial plan review request
# always specify model with -m (gpt-5.3-codex is optimal)
codex exec -m gpt-5.3-codex "Review this plan. No nitpicks. Only flag critical issues: {plan_full_path} (ref: {CLAUDE.md full_path})"

# updated plan review request
# without resume --last, the context from the first review is lost
codex exec resume --last -m gpt-5.3-codex "Plan updated. Review again. No nitpicks. Only flag critical issues: {plan_full_path} (ref: {CLAUDE.md full_path})"
```

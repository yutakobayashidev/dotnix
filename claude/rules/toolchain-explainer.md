# Toolchain Explainer

When the user mentions or asks about tools in an unfamiliar ecosystem, apply the following process.

## User Proficiency

| Level          | Areas                                                    |
| -------------- | -------------------------------------------------------- |
| **Proficient** | Web toolchain, TypeScript, Terraform, Linux, Nix, Python |
| **Learning**   | Go, Rust, BI, ETL / ELT, R Lang, Typst, Lua, neovim, Solidity |

No explanation needed for proficient areas. Apply this rule when tools from learning or unknown areas come up.

## Process

### 1. Compare Similar Tools

List the major alternatives in the category and briefly explain the differences.

- Design philosophy and use-case differences
- Analogies to technologies the user already knows (e.g. "This is the equivalent of ESLint in TypeScript")
- Trade-offs (performance, ecosystem maturity, learning curve)

### 2. Fetch Objective Metrics with repiq

Use the `repiq` skill to fetch objective metrics (stars, downloads, maintenance activity, etc.) for each candidate tool.

### 3. Present a Recommendation

Based on the metrics and comparison, recommend the option that best fits the user's use case. State the rationale explicitly — provide data-driven reasoning, not gut feelings.

## When NOT to Apply

- The user has already chosen a tool and is only asking how to use it
- The question is about a proficient-area tool
- A simple command usage question (a man-page-level answer suffices)

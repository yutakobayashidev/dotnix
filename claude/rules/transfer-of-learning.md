# Transfer of Learning

When explaining an unfamiliar concept, language, paradigm, or tool, accelerate comprehension by mapping it onto knowledge the user already possesses. New information sticks best when anchored to existing mental models.

**This is 0.5 → 1 catch-up, not 0 → 1.** The user already has a working mental model from a structurally similar technology they know well. Your job is to identify what carries over, then teach only the delta — the differences that close the gap. Do not explain from first principles; the user's existing knowledge is the 0.5.

## User Proficiency

| Level          | Areas                                                         |
| -------------- | ------------------------------------------------------------- |
| **Proficient** | Web toolchain, TypeScript, Terraform, Linux, Nix, Python      |
| **Learning**   | Go, Rust, BI, ETL / ELT, R Lang, Typst, Lua, neovim, Solidity |

No explanation scaffolding needed for proficient areas. Apply this rule when the subject falls outside them.

## Process

### 1. Find the Closest Known Analogue

Pick the most structurally similar concept from the user's proficient areas. The analogy doesn't need to be perfect — it needs to be a productive starting point.

### 2. Teach Through Contrast

Start from the analogy, then immediately highlight where it diverges. The gap between the known and the new is where learning happens.

- "Rust's ownership is like C++ RAII, but the compiler enforces it at compile time — there is no garbage collector and no runtime overhead."
- "Nix derivations are like Dockerfiles, but the build is pure: same inputs always produce the same output, and network access is blocked during builds."

### 3. Stack Differences Incrementally

Introduce divergences one at a time. Avoid dumping a full spec — layer each difference onto the now-adjusted mental model before adding the next.

### 4. Flag Where Intuition Misleads

Explicitly call out places where the user's existing intuition will steer them wrong. Preventing misconceptions is more valuable than adding information.

### 5. Ground with Objective Data (Optional)

When the user is orienting in an unfamiliar ecosystem, use the `repiq` skill to fetch adoption and maintenance metrics. Objective data helps calibrate which analogue is the right fit and whether a tool is mainstream or niche.

## When NOT to Apply

- The question is about a proficient-area topic
- A one-line factual answer suffices (e.g. "What flag does X take?")

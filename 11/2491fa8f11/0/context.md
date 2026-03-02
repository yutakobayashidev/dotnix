# Session Context

## User Prompts

### Prompt 1

CLAUDE.mdとAGENTS.md,tasks/をz-ai/に変えて

### Prompt 2

[Request interrupted by user for tool use]

### Prompt 3

gitの設定でglobalにignoreして、あとAGENTS.mdはおかない、今までのtasks/以下をrenameするイメージ

### Prompt 4

AGENTS.md,CLAUDE.mdはignoreしないで。z-aiをignoreする

### Prompt 5

kコミットして

### Prompt 6

これをclaude/CLAUDE.md、codex/AGENTS.mdに追加して Browser Automation (agent-browser)
agent-browser is available to check on the browser.

# 1. Open page (`--allow-private` is required to open localhost)
agent-browser open <url> --allow-private

# 2. Get element reference
agent-browser snapshot -i

# 3. Operate
agent-browser click @e<N>
agent-browser fill @e<N> "テキスト"

# 4. Save screenshot
agent-browser screenshot z-ai/screenshot.png

# ex. save credentials

agent-browser open <url> --profile ~/.browse...


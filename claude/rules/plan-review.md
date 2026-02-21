# 実装計画立案時のルール

- ユーザーに計画を提示する前に、codex コマンドで計画のレビューを行うこと。
- レビュー指示の文章は適宜調整すること。ただし codex コマンドは本質的じゃない指摘をしてくるので「瑣末な点へのクソリプするな。致命的な点のみ指摘しろ。」という指示は必ず入れた方がいい。
- `codex` の指摘がなくなるまでアップデート→レビューを繰り返すこと。

```bash
# initial plan review request
# 必ず -m でモデルを指定すること（gpt-5.3-codex が最適）
codex exec -m gpt-5.3-codex "このプランをレビューして。瑣末な点へのクソリプはしないで。致命的な点だけ指摘して: {plan_full_path} (ref: {CLAUDE.md full_path})"

# updated plan review request
# resume --last をつけないと最初のレビューの文脈が失われるから注意
codex exec resume --last -m gpt-5.3-codex "プランを更新したからレビューして。瑣末な点へのクソリプはしないで。致命的な点だけ指摘して: {plan_full_path} (ref: {CLAUDE.md full_path})"
```

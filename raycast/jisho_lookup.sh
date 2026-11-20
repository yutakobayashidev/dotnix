#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Jisho
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 📖

# クリップボードの内容を変数に保存
selectedText=$(pbpaste)

# 変数が空の場合はエラー
if [ -z "$selectedText" ]; then
	echo "クリップボードにテキストがありません。"
	osascript -e 'display notification "クリップボードにテキストがありません" with title "辞書検索失敗"'
	exit 1
fi

# クリップボードの値をURL用にエンコード
encodedText=$(python3 -c "import urllib.parse; print(urllib.parse.quote(input()))" <<<"$selectedText")

# 標準のブラウザでjishoを開く、検索パラメータ付き
open "https://jisho.org/search/${encodedText}"

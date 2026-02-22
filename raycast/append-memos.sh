#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Append Memos
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 🗒️
# @raycast.argument1 { "type": "text", "placeholder": "Take memos" }

current_time=$(date +"%H:%M")

memo=$(echo -n "$1" | jq -sRr @uri)

open --background "obsidian://advanced-uri?vault=Obsidian%20Vault&daily=true&mode=append&heading=%F0%9F%93%9D%20%E3%83%A1%E3%83%A2&data=-%20$current_time%20$memo"

#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Discord
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 📝
# @raycast.argument1 { "type": "text", "placeholder": "messages" }

messages=$(echo -n "$1" | jq -sRr @uri)

DISCORD_TOKEN=$(op item get "Discord Token" --reveal --fields label=認証情報)

CHANNEL_ID="1028287639918497822"

curl -X POST "https://discord.com/api/v9/channels/$CHANNEL_ID/messages" \
  -H "Authorization: $DISCORD_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
        \"content\": \"$messages\"
      }"
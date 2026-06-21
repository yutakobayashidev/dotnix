#!/usr/bin/env zsh
# ghauth: Copy the device-flow one-time code to clipboard (explicit invocation only)
# Security: If applications can trigger device flow automatically, an attacker
# could initiate the flow, plant a one-time code on your clipboard, and trick
# you into submitting it — compromising your access token via phishing.
# To prevent this, set GHTKN_ENABLE_DEVICE_FLOW=false so that only explicit
# invocations of ghauth start the device flow.

function ghauth() {
  ghtkn auth "$@" 2>&1 |
    tee >(grep -oE "[A-Z0-9]{4}-[A-Z0-9]{4}" --line-buffered | head -n1 | tr -d "\n" | pbcopy)
}

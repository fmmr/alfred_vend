#!/bin/bash
# Wrapper around `curl` for Alfred script filters that talk to FRAUD_DASH_URL.
# When the request fails (most commonly: not on VPN -> 403), emit a valid
# Alfred Script Filter JSON item that tells the user to connect, and whose
# `arg` opens AppGate SDP via the existing "Open URL" action.
#
# Usage:  fraud_dash.sh "<url>"
#
# stdout: either the upstream body (on 200) or an Alfred items JSON.

set -u

url="${1:?usage: fraud_dash.sh <url>}"

body=$(mktemp -t fraud_dash)
trap 'rm -f "$body"' EXIT

http_code=$(curl -q -s -S \
  --connect-timeout 3 \
  --max-time 10 \
  -o "$body" \
  -w '%{http_code}' \
  "$url" 2>/dev/null) || http_code="000"

if [ "$http_code" = "200" ]; then
  cat "$body"
  exit 0
fi

case "$http_code" in
  401|403) title="🔒 VPN required (HTTP $http_code) — opening AppGate SDP" ;;
  000)     title="🌐 fraud-dash unreachable — opening AppGate SDP" ;;
  5*)      title="⚠️ fraud-dash error (HTTP $http_code)" ;;
  *)       title="⚠️ Unexpected HTTP $http_code from fraud-dash" ;;
esac

# Bring AppGate to front so the user can connect. `open -a` is idempotent —
# running it on every keystroke while VPN is down just refocuses the window.
# Suppressed if AppGate isn't installed.
if [ -d "/Applications/AppGate SDP.app" ]; then
  open -a "AppGate SDP" >/dev/null 2>&1 &
fi

# arg goes downstream to the openurl action — we hand back the original URL so
# "↩" reloads in the browser once the user is on VPN (also keeps Cmd-C useful).
cat <<JSON
{
  "items": [
    {
      "uid": "fraud-dash-vpn-error",
      "title": "$title",
      "subtitle": "↩ retries in browser  ·  Cmd-L copies request URL",
      "arg": "$url",
      "valid": true,
      "icon": { "path": "/Applications/AppGate SDP.app/Contents/Resources/icon.icns" },
      "text": { "copy": "$url", "largetype": "$url" }
    }
  ]
}
JSON

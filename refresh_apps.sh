if [ "$1" = "--local" ]; then
  echo "running locally"
  dash_url=http://local.finn.no:8080/alfred
else
  dash_url=https://fraud-dash.horizontal.svc.finn.no/alfred
fi

# Bail early with a helpful message if VPN is down (403) or host unreachable.
probe_code=$(curl -q -s -o /dev/null -w '%{http_code}' \
  --connect-timeout 3 --max-time 10 "$dash_url/apps")
case "$probe_code" in
  200)
    : # good, continue
    ;;
  401|403)
    echo "🔒 fraud-dash returned HTTP $probe_code — VPN required."
    echo "   Launching AppGate SDP..."
    open -a "AppGate SDP" 2>/dev/null
    exit 1
    ;;
  000)
    echo "🌐 Cannot reach $dash_url (no network / DNS). Launching AppGate SDP..."
    open -a "AppGate SDP" 2>/dev/null
    exit 1
    ;;
  *)
    echo "⚠️ Unexpected HTTP $probe_code from $dash_url — aborting."
    exit 1
    ;;
esac

for app in apps slack apps_sub; do
  echo "============================================"
  echo "  Updating: $app"
  curl -q -s  $dash_url/$app |jq 'del(.cache)' > $app.new
  diff $app.json $app.new

  if test $? -eq 0; then
    echo "  $app already updated"
    rm $app.new
  else
    echo "  Found diff for $app"
    if [ -f $app.json ]; then
      echo "  Creating backup: $app.bak"
      cp $app.json $app.bak
    fi
    mv $app.new $app.json
  fi
done
echo "============================================"

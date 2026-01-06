if [ "$1" = "--local" ]; then
  dash_url=http://local.finn.no:8080/alfred
else
  dash_url=https://fraud-dash.horizontal.svc.finn.no/alfred
fi
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

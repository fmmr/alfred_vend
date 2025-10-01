#!/bin/bash

brand="$1"   # set by Arg & Vars upstream
result=""

# Common Solr params
params="?defType=dismax&qt=alert_polling&fl=id&rows=1&wt=csv&facet=false&sort=timestamp%20desc&csv.header=false"

case "$brand" in
  # prod
  finn)       url="https://solr-odin.svc.prod.finn.no/solr/finn/select$params" ;;
  dba)        url="https://solr-odin.svc.dba.dk/solr/ads/select$params" ;;
  blocket)    url="https://solr-odin.svc.blocket.se/solr/ads/select$params" ;;
  tori)       url="https://solr-odin.svc.tori.fi/solr/ads/select$params" ;;
  # dev
  finndev)    url="https://solr-odin.svc.dev.finn.no/solr/finn/select${params}&qf=id" ;;
  dbadev)     url="https://solr-odin.svc.dev.dba.dk/solr/ads/select$params" ;;
  blocketdev) url="https://solr-odin.svc.dev.blocket.se/solr/ads/select$params" ;;
  toridev)    url="https://solr-odin.svc.dev.tori.fi/solr/ads/select$params" ;;
  *)
    echo "Unknown brand: $brand" >&2
    exit 1
    ;;
esac

result=$(curl -s "$url")

# Debug log (optional)
# echo -n "adid: $result" >&2

# Plain output (to clipboard + notification)
echo "$result"

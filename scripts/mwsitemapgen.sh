#!/bin/bash

SCRIPT=$MW_HOME/maintenance/generateSitemap.php
logfileName=mwsitemapgen_log

# Verify the delay is >= 1, otherwise fall back to 1
if [ "$MW_SITEMAP_PAUSE_DAYS" -lt "1" ]; then
    MW_SITEMAP_PAUSE_DAYS=1
fi
# Convert to seconds (suffixed sleep command has issues on OSX)
SLEEP_DAYS=$((MW_SITEMAP_PAUSE_DAYS * 60 * 60 * 24))

SITE_SERVER=$WG_SITE_SERVER
# Fallback to https:// scheme if it's protocol-relative
if [[ $SITE_SERVER == "//"* ]]; then
    SITE_SERVER="https:$SITE_SERVER"
fi

GOOGLE_PING_URL="https://www.google.com/ping?sitemap=${SITE_SERVER}${WG_SCRIPT_PATH}/sitemap/sitemap-index-mediawiki.xml"

echo "Starting sitemap generator (in 30 seconds)..."
# Wait three minutes after the server starts up to give other processes time to get started
sleep 30
echo Sitemap generator started.
while true; do
    logFilePrev="$logfileNow"
    logfileNow="$MW_LOG/$logfileName"_$(date +%Y%m%d)
    if [ -n "$logFilePrev" ] && [ "$logFilePrev" != "$logfileNow" ]; then
        /rotatelogs-compress.sh "$logfileNow" "$logFilePrev" &
    fi

    date >> "$logfileNow"

    # generate the sitemap
    php "$SCRIPT" \
      --fspath="$MW_HOME/sitemap/" \
      --urlpath=w/sitemap/ \
      --compress yes \
      --server="$MW_SITE_SERVER" \
      --skip-redirects \
      --identifier=mediawiki \
      >> "$logfileNow" 2>&1

    # sending the sitemap to google
    echo "sending to Google -> $GOOGLE_PING_URL"
    curl --silent "$GOOGLE_PING_URL" > /dev/null

    # Wait some seconds to let the CPU do other things, like handling web requests, etc
    echo mwsitemapgen waits for "$SLEEP_DAYS" seconds... >> "$logfileNow"
    sleep "$SLEEP_DAYS"
done

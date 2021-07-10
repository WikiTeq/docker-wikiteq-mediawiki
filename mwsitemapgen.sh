#!/bin/bash

rotatelogs=( /usr/sbin/rotatelogs -c -f -l -L "$MW_LOG/mwsitemapgen_log.current" "$MW_LOG/mwsitemapgen_log_%Y%m%d" 86400 )

SCRIPT=$MW_HOME/maintenance/generateSitemap.php
# Verify the delay is >= 1, otherwise fall back to 1
if [ "$MW_SITEMAP_PAUSE_DAYS" -lt "1" ]; then
    MW_SITEMAP_PAUSE_DAYS=1
fi
# Convert to seconds (suffixed sleep command has issues on OSX)
SLEEP_DAYS=$((MW_SITEMAP_PAUSE_DAYS * 60 * 60 * 24))

echo "Starting sitemap generator (in 30 seconds)..."
# Wait three minutes after the server starts up to give other processes time to get started
sleep 30
echo Sitemap generator started.
while true; do
    date | "${rotatelogs[@]}"
    php "$SCRIPT" \
      --fspath="$MW_HOME/sitemap/" \
      --urlpath=w/sitemap/ \
      --compress yes \
      --server="$MW_SITE_SERVER" \
      --skip-redirects \
      --identifier=mediawiki \
      2>&1 | "${rotatelogs[@]}"

    # Wait some seconds to let the CPU do other things, like handling web requests, etc
    echo mwsitemapgen waits for "$SLEEP_DAYS" seconds... | "${rotatelogs[@]}"
    sleep "$SLEEP_DAYS"
done

#!/bin/bash

LIMIT_CMD="nice -n $MW_JOBS_NICE ionice -c $MW_JOBS_IONICE"

SCRIPT=$MW_HOME/maintenance/generateSitemap.php
logfileName=mwsitemapgen_log

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
    logFilePrev="$logfileNow"
    logfileNow="$MW_LOG/$logfileName"_$(date +%Y%m%d)
    if [ -n "$logFilePrev" ] && [ "$logFilePrev" != "$logfileNow" ]; then
        /rotatelogs-compress.sh "$logfileNow" "$logFilePrev" &
    fi

    date >> "$logfileNow"

    # generate the sitemap
    $LIMIT_CMD php "$SCRIPT" \
      --fspath="$MW_HOME/sitemap/" \
      --urlpath=w/sitemap/ \
      --compress yes \
      --server="$MW_SITE_SERVER" \
      --skip-redirects \
      --identifier=mediawiki \
      >> "$logfileNow" 2>&1

    # Wait some seconds to let the CPU do other things, like handling web requests, etc
    echo mwsitemapgen waits for "$SLEEP_DAYS" seconds... >> "$logfileNow"
    sleep "$SLEEP_DAYS"
done

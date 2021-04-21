#!/bin/bash

SCRIPT=$MW_HOME/maintenance/generateSitemap.php
echo Starting sitemap generator...
# Wait three minutes after the server starts up to give other processes time to get started
sleep 180
echo Sitemap generator started.
while true; do
    php $SCRIPT --fspath=$MW_HOME/sitemap/ --urlpath=w/sitemap/ --compress yes

    # Wait some seconds to let the CPU do other things, like handling web requests, etc
    echo mwsitemapgen waits for "$MW_SITEMAP_PAUSE" seconds...
    sleep "$MW_SITEMAP_PAUSE"
done

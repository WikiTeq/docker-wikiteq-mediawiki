#!/bin/bash

rotatelogs=( /usr/sbin/rotatelogs -c -f -l -L "$MW_LOG/mwtranscoder_log.current" "$MW_LOG/mwtranscoder_log_%Y%m%d" 86400 )

RJ=$MW_HOME/maintenance/runJobs.php
echo "Starting transcoder (in 180 seconds)..."
# Wait three minutes after the server starts up to give other processes time to get started
sleep 180
echo Transcoder started.
while true; do
    date | "${rotatelogs[@]}"
    php "$RJ" --type webVideoTranscodePrioritized --maxjobs=10 2>&1 | "${rotatelogs[@]}"
    sleep 1
    php "$RJ" --type webVideoTranscode --maxjobs=1 2>&1 | "${rotatelogs[@]}"

    # Wait some seconds to let the CPU do other things, like handling web requests, etc
    echo mwtranscoder waits for "$MW_JOB_TRANSCODER_PAUSE" seconds... | "${rotatelogs[@]}"
    sleep "$MW_JOB_TRANSCODER_PAUSE"
done

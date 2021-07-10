#!/bin/bash

RJ=$MW_HOME/maintenance/runJobs.php

rotatelogs=( /usr/sbin/rotatelogs -c -f -l -p /rotatelogs-compress.sh -L "$MW_LOG/mwjobrunner_log.current" "$MW_LOG/mwjobrunner_log_%Y%m%d" 86400 )

echo "Starting job runner (in 10 seconds)..."
# Wait 10 seconds after the server starts up to give other processes time to get started
sleep 10
echo Job runner started.
while true; do
    date | "${rotatelogs[@]}"
    # Job types that need to be run ASAP mo matter how many of them are in the queue
    # Those jobs should be very "cheap" to run
    php "$RJ" --type="enotifNotify" 2>&1 | "${rotatelogs[@]}"
    sleep 1
    php "$RJ" --type="createPage" 2>&1 | "${rotatelogs[@]}"
    sleep 1
    php "$RJ" --type="refreshLinks" 2>&1 | "${rotatelogs[@]}"
    sleep 1
    php "$RJ" --type="htmlCacheUpdate" --maxjobs=500 2>&1 | "${rotatelogs[@]}"
    sleep 1
    # Everything else, limit the number of jobs on each batch
    # The --wait parameter will pause the execution here until new jobs are added,
    # to avoid running the loop without anything to do
    php "$RJ" --maxjobs=10 2>&1 | "${rotatelogs[@]}"

    # Wait some seconds to let the CPU do other things, like handling web requests, etc
    echo mwjobrunner waits for "$MW_JOB_RUNNER_PAUSE" seconds... | "${rotatelogs[@]}"
    sleep "$MW_JOB_RUNNER_PAUSE"
done

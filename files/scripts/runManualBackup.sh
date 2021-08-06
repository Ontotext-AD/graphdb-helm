#!/usr/bin/env bash

IFS='.'

wanted_date=$(echo $1 | tr '.' '-')
repo_name=$2
topology=$3
current_date=$(date +'%Y-%m-%d %H:%M')

echo "Wanted date: $wanted_date"
echo "Current date: $current_date"

echo "The backup will start on $wanted_date. The script will sleep until then!"

wanted_date_sec=$(date -d "$wanted_date" +%s)
current_date_sec=$(date -d "$current_date" +%s)

sleep_seconds=$(( wanted_date_sec - current_date_sec ))
echo $sleep_seconds

if [ $sleep_seconds -gt 0 ]; then
  sleep $sleep_seconds
  /usr/local/bin/backup.sh ${repo_name} ${topology}
else
  echo "The wanted date is in the past, backup will not be triggered!"
fi

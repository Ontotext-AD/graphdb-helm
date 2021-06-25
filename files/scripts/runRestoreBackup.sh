#!/usr/bin/env bash

wanted_date=$(echo $1 | tr '.' '-')
repo_name=$2
restore_from_backup=$3
#in case the user passed the exact folder name, not only the date
restore_from_backup=$(echo $restore_from_backup)
current_date=$(date +'%Y-%m-%d %H:%M')

echo "Backup to restore from: ${restore_from_backup}"
echo "Wanted date: $wanted_date"
echo "Current date: $current_date"

echo "The backup will start on $wanted_date. The script will sleep until then!"

wanted_date_sec=$(date -d "$wanted_date" +%s)
current_date_sec=$(date -d "$current_date" +%s)

sleep_seconds=$(( wanted_date_sec - current_date_sec ))
echo $sleep_seconds
#In case the backup fails, it will still run if the pod is rescheduled
if [ $sleep_seconds -gt 0 ]; then
  sleep $sleep_seconds

curl -o response.json -H 'content-type: application/json' -d "{\"type\":\"exec\",\"mbean\":\"ReplicationCluster:name=ClusterInfo\/${repo_name}\",\"operation\":\"restoreFromImage\",\"arguments\":[\"$repo_name-$(echo ${restore_from_backup} | rev | cut -d '/' -f1 | rev )\"]}" http://graphdb-master-1:7200/jolokia/
  if grep -q '"status":200' "response.json"; then
    echo "Successfully restored"
  else
    echo "Error during restore: "
    cat response.json
  fi
else
  echo "The wanted date is in the past, restore will not be triggered!"
fi

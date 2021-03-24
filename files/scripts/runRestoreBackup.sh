#!/usr/bin/env bash

wanted_date=$(echo $1 | tr ' ' '-' | tr ':' '-' | tr '.' '-')
repo_name=$2
restore_from_backup=$3

echo ${wanted_date}
echo $(date +'%d-%m-%Y-%H-%M')

echo ${repo_name}

if [[ $(date +'%d-%m-%Y-%H-%M') == ${wanted_date} ]]
then
  curl -H 'content-type: application/json' -d "{\"type\":\"exec\",\"mbean\":\"ReplicationCluster:name=ClusterInfo\/${repo_name}\",\"operation\":\"restoreFromImage\",\"arguments\":[\"${restore_from_backup}\"]}" http://graphdb-master-1:7200/jolokia/
fi


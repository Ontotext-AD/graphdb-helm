#!/usr/bin/env sh

set -eu
#TODO: Add a function which sets a master as read only
function waitService() {
  address=$1

  attempt_counter=0
  max_attempts=100

  echo "Waiting for ${address}"
  until $(curl --output /dev/null --silent --fail ${address}); do
    if [[ ${attempt_counter} -eq ${max_attempts} ]];then
      echo "Max attempts reached"
      exit 1
    fi

    printf '.'
    attempt_counter=$(($attempt_counter+1))
    sleep 5
  done
}

waitMaster() {
  master_address=$1
  master_repo=$2

  waitService "${master_address}/rest/repositories"
  waitService "${master_address}/rest/repositories/${master_repo}/size"
  waitService "${master_address}/rest/cluster/masters/${master_repo}"
}

linkWorker() {
  master_address=$1
  worker_address=$2
  repository=$3
  master_repo=$4

  waitService "http://localhost:7200/repositories/${repository}/size"

  worker_repo_endpoint="${worker_address}/repositories/${repository}"

  echo "Adding worker as remote location"

  curl ${master_address}/rest/locations -H 'Content-Type:application/json' \
  -H 'Accept: application/json, text/plain, */*' \
  --data-raw "{\"uri\":\"${worker_address}\",\"username\":\"\", \"password\":\"\", \"active\":\"false\"}"

  echo "Linking worker"
  curl -o response.json -sf -X POST ${master_address}/jolokia/ \
      --header 'Content-Type: multipart/form-data' \
      --data-raw "{
        \"type\": \"exec\",
        \"mbean\": \"ReplicationCluster:name=ClusterInfo/${repository}\",
        \"operation\": \"addClusterNode\",
        \"arguments\": [
          \"${worker_repo_endpoint}\", 0, true
        ]
      }"

  # Jolokia returns HTTP 200 even if the response is a failure...
  # Parse the response to check the real status
  status=$(jq '.status' response.json)
  if [[ "${status}" -ne "200" ]]; then
    echo "Linking failed for worker"
    exit 1
  fi

  echo "Linked"
}

"$@"

#!/usr/bin/env bash

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

waitMasters() {
  masters_count=$1
  master_repo=$2

  for (( c=1; c<=$masters_count; c++ ))
  do
    master_address=http://graphdb-master-$c:7200
    waitService "${master_address}/rest/repositories"
    waitService "${master_address}/rest/repositories/${master_repo}/size"
    waitService "${master_address}/rest/cluster/masters/${master_repo}"
  done
}

waitWorkers() {
  workers_count=$1
  workers_repo=$2

  for (( c=1; c<=$workers_count; c++ ))
  do
    workers_address=http://graphdb-worker-$c:7200
    waitService "${workers_address}/rest/repositories"
    waitService "${workers_address}/rest/repositories/${workers_repo}/size"
  done
}

linkWorkerToMaster() {
  master_address=http://$1:7200
  worker_repository=$4
  master_repo=$2
  workers_count=$3
  for (( c=1; c<=$workers_count; c++ ))
  do
    worker_address=http://graphdb-worker-$c:7200
    worker_repo_endpoint="${worker_address}/repositories/${worker_repository}"

    echo "Adding worker ${worker_address} as remote location"

    curl ${master_address}/rest/locations -H 'Content-Type:application/json' \
      -H 'Accept: application/json, text/plain, */*' \
      --data-raw "{\"uri\":\"${worker_address}\",\"username\":\"\", \"password\":\"\", \"active\":\"false\"}"

    echo "Linking worker with repo endpoint ${worker_repo_endpoint}"
    curl -o response.json -sf -X POST ${master_address}/jolokia/ \
      --header 'Content-Type: multipart/form-data' \
      --data-raw "{
        \"type\": \"exec\",
        \"mbean\": \"ReplicationCluster:name=ClusterInfo/${master_repo}\",
        \"operation\": \"addClusterNode\",
        \"arguments\": [
          \"${worker_repo_endpoint}\", 0, true
        ]
      }"
     if grep -q '"status":200' "response.json"; then
        echo "Linking successfull for worker $worker_address"
    else
        echo "Linking failed for worker ${worker_address}"
        exit 1
    fi
  done

  echo "Cluster linked successfully!"
}
#workersCount, workerRepo
waitWorkers $4 $5
#mastersCount, mastersRepo
waitMasters $2 $3
#1 master, multiple workers. Args: master to link to, master repo, workers count, workers repo
linkWorkerToMaster graphdb-master-1 $3 $4 $5

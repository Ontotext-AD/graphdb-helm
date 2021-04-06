#!/usr/bin/env bash

set -eu

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
  master_repo=$2
  worker_address=http://$3:7200
  worker_repository=$4

  worker_repo_endpoint="${worker_address}/repositories/${worker_repository}"
  waitService "${worker_address}/rest/repositories"
  waitService "${worker_address}/rest/repositories/${worker_repository}/size"

  waitService "${master_address}/rest/repositories"
  waitService "${master_address}/rest/repositories/${worker_repository}/size"

  addInstanceAsRemoteLocation $1 $3

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

  echo "Worker linked successfully!"
}

setInstanceReadOnly() {
  instance_address=http://$1:7200
  repository=$2

  echo "Setting instance $instance_address as readonly"

  curl -o response.json -H 'content-type: application/json' -d "{\"type\":\"write\",\"mbean\":\"ReplicationCluster:name=ClusterInfo\/$repository\",\"attribute\":\"ReadOnly\",\"value\":true}" $instance_address/jolokia

  if grep -q '"status":200' "response.json"; then
      echo "Successfully set instance $instance_address as read only"
  else
      echo "Failed setting instance read only $instance_address"
      exit 1
  fi
}

setInstanceMuted() {
  instance_address=http://$1:7200
  repository=$2

  echo "Setting instance $instance_address as muted"

  curl -o response.json -H 'content-type: application/json' -d "{\"type\":\"write\",\"mbean\":\"ReplicationCluster:name=ClusterInfo\/$repository\",\"attribute\":\"Mode\",\"value\":\"MUTE\"}" $instance_address/jolokia/

  if grep -q '"status":200' "response.json"; then
      echo "Successfully set instance $instance_address as muted"
  else
      echo "Failed setting instance muted $instance_address"
      exit 1
  fi
}

addInstanceAsRemoteLocation() {
  master_address=http://$1:7200
  worker_address=http://$2:7200

  echo "Adding worker $worker_address as remote location of $master_address"

  curl ${master_address}/rest/locations -o response.json -H 'Content-Type:application/json' -H 'Accept: application/json, text/plain, */*' --data-raw "{\"uri\":\"${worker_address}\",\"username\":\"\", \"password\":\"\", \"active\":\"false\"}"

  if grep -q 'Success\|connected' "response.json"; then
      echo "Successfully added $worker_address as remote location of $master_address"
  else
      echo "Failed adding instance $worker_address as remote location of $master_address"
      exit 1
  fi
}

setSyncPeer() {
  instance1_address=http://$1:7200
  instance2_address=http://$3:7200
  instance1_repository=$2
  instance2_repository=$4

  addInstanceAsRemoteLocation $1 $3

  echo "Setting $instance2_address as sync pear for $instance1_address"

  curl -o response.json -H 'content-type: application/json' -d "{\"type\":\"exec\",\"mbean\":\"ReplicationCluster:name=ClusterInfo\/$instance1_repository\",\"operation\":\"addSyncPeer\",\"arguments\":[\"$instance2_address/repositories/$instance2_repository\",\"$instance2_address/repositories/$instance2_repository\"]}"   $instance1_address/jolokia/
  if grep -q '"status":200' "response.json"; then
      echo "Successfully set sync peer between $instance1_address and $instance2_address"
  else
      echo "Failed setting sync peer between $instance1_address and $instance2_address"
      exit 1
  fi
}

linkAllWorkersToMaster() {
  worker_repository=$4
  master_repo=$2
  workers_count=$3
  for (( c=1; c<=$workers_count; c++ ))
  do
    worker_address=graphdb-worker-$c
    linkWorkerToMaster $1 $master_repo $worker_address $worker_repository
  done

  echo "Cluster linked successfully!"
}

waitAllInstances() {
  #workersCount, workerRepo
  waitWorkers $3 $4
  #mastersCount, mastersRepo
  waitMasters $1 $2
}

link_1m_3w() {
  #masters count, master repo, workers count, worker repo
  waitAllInstances $1 $2 $3 $4

  #1 master, multiple workers. Args: master to link to, master repo, workers count, workers repo
  linkAllWorkersToMaster graphdb-master-1 $2 $3 $4
}

"$@"

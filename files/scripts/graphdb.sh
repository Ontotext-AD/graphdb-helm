#!/usr/bin/env bash

set -eu

function waitService {
  local address=$1
  local token=$2

  local attempt_counter=0
  local max_attempts=100

  echo "Waiting for ${address}"
  until $(curl --output /dev/null -fsSL -m 5 -H "Authorization: Basic ${token}" --silent --fail ${address}); do
    if [[ ${attempt_counter} -eq ${max_attempts} ]];then
      echo "Max attempts reached"
      exit 1
    fi

    printf '.'
    attempt_counter=$(($attempt_counter+1))
    sleep 5
  done
}

function waitMasters {
  local masters_count=$1
  local master_repo=$2
  local token=$3

  for (( c=1; c<=$masters_count; c++ ))
  do
    master_address=http://graphdb-master-$c:7200
    waitService "${master_address}/rest/repositories" $token
    waitService "${master_address}/rest/repositories/${master_repo}/size" $token
    waitService "${master_address}/rest/cluster/masters/${master_repo}" $token
  done
}

function waitWorkers {
  local workers_count=$1
  local workers_repo=$2
  local token=$3

  for (( c=1; c<=$workers_count; c++ ))
  do
    local workers_address=http://graphdb-worker-$c:7200
    waitService "${workers_address}/rest/repositories" $token
    waitService "${workers_address}/rest/repositories/${workers_repo}/size" $token
  done
}

function linkWorkerToMaster {
  local master_address=http://$1:7200
  local master_repo=$2
  local worker_address=http://$3:7200
  local worker_repository=$4
  local token=$5

  local worker_repo_endpoint="${worker_address}/repositories/${worker_repository}"
  waitService "${worker_address}/rest/repositories" $token
  waitService "${worker_address}/rest/repositories/${worker_repository}/size" $token

  waitService "${master_address}/rest/repositories" $token
  waitService "${master_address}/rest/repositories/${worker_repository}/size" $token

  addInstanceAsRemoteLocation $1 $3 $token

  echo "Linking worker with repo endpoint ${worker_repo_endpoint}"
  curl -o response.json -sSL -m 5 -X POST -H "Authorization: Basic ${token}" ${master_address}/jolokia/ \
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
      echo "Linking failed for worker ${worker_address} received response:"
      cat response.json
      exit 1
  fi

  echo "Worker linked successfully!"
}

function setInstanceReadOnly {
  local instance_address=http://$1:7200
  local repository=$2
  local token=$3

  echo "Setting instance $instance_address as readonly"

  curl -o response.json -sSL -m 5 -H 'content-type: application/json' -H "Authorization: Basic $token" -d "{\"type\":\"write\",\"mbean\":\"ReplicationCluster:name=ClusterInfo\/$repository\",\"attribute\":\"ReadOnly\",\"value\":true}" $instance_address/jolokia

  if grep -q '"status":200' "response.json"; then
      echo "Successfully set instance $instance_address as read only"
  else
      echo "Failed setting instance read only $instance_address received response:"
      cat response.json
      exit 1
  fi
}

function setInstanceMuted {
  local instance_address=http://$1:7200
  local repository=$2
  local token=$3

  echo "Setting instance $instance_address as muted"

  curl -o response.json -sSL -m 5 -H 'content-type: application/json' -H "Authorization: Basic $token" -d "{\"type\":\"write\",\"mbean\":\"ReplicationCluster:name=ClusterInfo\/$repository\",\"attribute\":\"Mode\",\"value\":\"MUTE\"}" $instance_address/jolokia/

  if grep -q '"status":200' "response.json"; then
      echo "Successfully set instance $instance_address as muted"
  else
      echo "Failed setting instance muted $instance_address received response:"
      cat response.json
      exit 1
  fi
}

function addInstanceAsRemoteLocation {
  local master_address=http://$1:7200
  local worker_address=http://$2:7200
  local token=$3
  local username=$(echo $token | base64 -d | cut -d':' -f1)
  local password=$(echo $token | base64 -d | cut -d':' -f2)

  echo "Adding worker $worker_address as remote location of $master_address"
  echo "${username} -> pass ${password}"
  echo "{\"uri\":\"${worker_address}\",\"username\":\"${username}\", \"authType\":\"basic\", \"password\":\"${password}\", \"active\":\"false\"}"
  curl ${master_address}/rest/locations -sSL -m 5 -o response.json -H "Authorization: Basic $token" -H 'Content-Type:application/json' -H 'Accept: application/json, text/plain, */*' --data-raw "{\"uri\":\"${worker_address}\", \"username\":\"${username}\", \"authType\":\"basic\", \"password\":\"${password}\", \"active\":\"false\"}"

  if grep -q 'Success\|connected' "response.json"; then
      echo "Successfully added $worker_address as remote location of $master_address"
  else
      echo "Failed adding instance $worker_address as remote location of $master_address received response:"
      cat response.json
      exit 1
  fi
}

function setSyncPeer {
  local instance1_address=http://$1:7200
  local instance2_address=http://$3:7200
  local instance1_repository=$2
  local instance2_repository=$4
  local token=$5

  addInstanceAsRemoteLocation $1 $3 $token

  echo "Setting $instance2_address as sync peer for $instance1_address"

  curl -o response.json -sSL -m 5 -H 'content-type: application/json' -H "Authorization: Basic $token" -d "{\"type\":\"exec\",\"mbean\":\"ReplicationCluster:name=ClusterInfo\/$instance1_repository\",\"operation\":\"addSyncPeer\",\"arguments\":[\"$instance2_address/repositories/$instance2_repository\",\"$instance2_address/repositories/$instance2_repository\"]}"   $instance1_address/jolokia/
  if grep -q '"status":200' "response.json"; then
      echo "Successfully set sync peer between $instance1_address and $instance2_address"
  else
      echo "Failed setting sync peer between $instance1_address and $instance2_address received response:"
      cat response.json
      exit 1
  fi

  setNodeID $1 $2 $token
  setNodeID $3 $4 $token
}

function linkAllWorkersToMaster {
  local worker_repository=$4
  local master_repo=$2
  local workers_count=$3
  local token=$5

  for (( c=1; c<=$workers_count; c++ ))
  do
    local worker_address=graphdb-worker-$c
    linkWorkerToMaster $1 $master_repo $worker_address $worker_repository $token
  done

  echo "Cluster linked successfully!"
}

function unlinkWorker {
  local master_repo=$1
  local master_address=$2
  local worker_address=$3
  local worker_repo=$4
  local token=$5

  echo "Unlinking $worker_address from $master_address"
  curl -X 'DELETE' "http://$master_address:7200/graphdb/rest/cluster/masters/$master_repo/workers?masterLocation=local" -sSL -m 5 -H "Authorization: Basic $token" --data-urlencode "workerURL=http://$worker_address:7200/repositories/$worker_repo"
  curl -o response.json -H 'content-type: application/json' -sSL -m 5 -H "Authorization: Basic $token" -d "{\"type\":\"exec\",\"mbean\":\"ReplicationCluster:name=ClusterInfo\/$instance1_repository\",\"operation\":\"addSyncPeer\",\"arguments\":[\"$instance2_address/repositories/$instance2_repository\",\"$instance2_address/repositories/$instance2_repository\"]}"   $instance1_address/jolokia/
  if grep -q '"status":200' "response.json"; then
      echo "Successfully unlinked $master_address from $worker_address"
  else
      echo "Failed unlinking $master_address from $worker_address received response:"
      cat response.json
      exit 1
  fi
}

function unlinkDownScaledInstances {
  local master_repo=$1
  local masters_count=$2
  local workers_count=$3
  local worker_repo=$4
  local token=$5

  for (( c=1; c<=$masters_count; c++ ))
  do
    local master_address=graphdb-master-$c
    curl -o response.json -sSL -m 5 -H 'content-type: application/json'  -H "Authorization: Basic $token" -d "{\"type\":\"read\",\"mbean\":\"ReplicationCluster:name=ClusterInfo\/$master_repo\",\"attribute\":\"NodeStatus\"}"   http://$master_address:7200/jolokia/
    local linked_workers_count=$(grep -ow ON "response.json" | wc -l)
    local missing_workers_count=$(grep -ow ON "response.json" | wc -l)

    if $linked_workers_count != $workers_count ; then
      echo "The cluster has instances that are not connected, but they should be. Can't determine workers which must be disconnected from the cluster, please do it manually!"
    else
      local worker_to_be_unlinked=$linked_workers_count+$missing_workers_count
      for (( x=1; x<=$missing_workers_count; x++ ))
      do
        unlinkWorker $master_repo $master_address graphdb-worker-$worker_to_be_unlinked $worker_repo $token
        local worker_to_be_unlinked=$worker_to_be_unlinked-1
      done
    fi
    linkWorkerToMaster $1 $master_repo $worker_address $worker_repository $token
  done

  echo "Cluster linked successfully!"
}

function waitAllInstances {
  #workersCount, workerRepo, token
  waitWorkers $3 $4 $5
  #mastersCount, mastersRepo, token
  waitMasters $1 $2 $5
}

function link_1m_3w {
  #masters count, master repo, workers count, worker repo, token
  waitAllInstances $1 $2 $3 $4 $5

  #1 master, multiple workers. Args: master to link to, master repo, workers count, workers repo, token
  linkAllWorkersToMaster graphdb-master-1 $2 $3 $4 $5
}

function setNodeID {
  local instance_address=http://$1:7200
  local instance_repository=$2
  local token=$3
  echo "Setting NodeID for $instance_address"
  curl -o response.json -sSL -m 5 -H 'content-type: application/json' -H "Authorization: Basic $token" -d "{\"type\":\"write\",\"mbean\":\"ReplicationCluster:name=ClusterInfo\/$instance_repository\",\"attribute\":\"NodeID\",\"value\":\"$instance_address/repositories/$instance_repository\"}" $instance_address/jolokia/
  if grep -q '"status":200' "response.json"; then
      echo "Successfully set NodeID for $instance_address"
  else
      echo "Failed setting NodeID for $instance_address received response:"
      cat response.json
      exit 1
  fi
}

function setJmxAttribute {
  local instance_address=http://$1:7200
  local instance_repository=$2
  local token=$3
  local attrName=$4
  local attrValue=$5

  echo "Setting JMX attribute $attrName to $attrValue for $instance_address and repository $instance_repository"
  curl -o response.json -sSL -m 5 \
    -H 'content-type: application/json' \
    -H "Authorization: Basic $token" \
    -d "{\"type\":\"write\",\"mbean\":\"ReplicationCluster:name=ClusterInfo\/$instance_repository\",\"attribute\":\"$attrName\",\"value\":\"$attrValue\"}" $instance_address/jolokia/

    if grep -q '"status":200' "response.json"; then
        echo "Successfully set JMX attribute $attrName to $attrValue"
    else
        echo "Failed setting JMX attribute $attrName to $attrValue"
        cat response.json
        exit 1
    fi
}

"$@"

#!/usr/bin/env bash

# Required commands:
# 1. Patch the cluster config
#   - take current - curl GET node-0/rest/cluster/config
#   - compare it with one in values.yaml
#   - if different - curl PATCH node-o/rest/cluster/config
#   - else do nothing
# 2. Add/Remove nodes
#   - parse - curl GET node-0/rest/cluster/config for number of nodes
#   - compare with node count in values.yaml
#   - if cluster nodes = 1 do nothing, create cluster would have taken care of such situation
#   - if cluster nodes = values.yaml do nothing
#   ADD
#   - if cluster nodes < values.yaml user - curl post /rest/cluster/config/node to add extra
#   REMOVE
#   - if cluster nodes > values.yaml use - curl DELETE /rest/cluster/config/node to delete extra
#   - if cluster nodes > values.yaml = 1 use - curl DELETE /rest/cluster/config to delete cluster and figure out the services/external proxy situation
#
#
#  POSSIBLE ISSUES:
#  if all nodes need to be ready for a process, solution: - curl GET /rest/cluster/group/status and parse their statuses and count from it
#  if an API requires leader i have no idea in what state the external proxy would be
#
#  After things are done and working merge this script with graphdb.sh

function patchCluster {
  #curl to leader/loadBalancer to patch cluster
  echo "Not implemented yet."
}

function updateClusterNodes {
  #temporarly for testing scale/patch it by deleting it as a pre-upgrade/pre-rollback, create cluster will take care of the rest
  local expectedNodes=$1
  local authToken=$2
  if [ $expectedNodes -lt 2 ]; then
    deleteCluster
  fi
  local currentNodes=$(getNodeCountInCurrentCluster authToken)
  if [ $expectedNodes -lt $currentNodes ]; then
    echo "Scaling down!"
    removeNodes $expectedNodes $expectedNodes $authToken
  elif [ $expectedNodes -lt $currentNodes ]; then
        echo "Scaling up!"
        addNodes $expectedNodes $expectedNodes $authToken
  fi
}

function removeNodes {
  local expectedNodes=$1
  local currentNodes=$2
  local authToken=$3
  local nodes=""
  for ((i=$expectedNodes;i<$currentNodes;i++)) do
    nodes=${nodes}\"graphdb-node-$i.graphdb-node:7300\"
    if [ $i -lt $(expr $currentNodes - 1) ]; then
      nodes=${nodes}\,
    fi
  done
  nodes=\{\"nodes\":\[${nodes}\]\}
  curl -X DELETE --header 'Content-Type: application/json' --header 'Accept: application/json' --header "Authorization: Basic ${token}" -d "$nodes"  'http://graphdb-cluster-proxy:7200/rest/cluster/config/node'
}

function addNodes {
  local expectedNodes=$1
  local currentNodes=$2
  local nodes=""
  for ((i=$currentNodes;i<$expectedNodes;i++)) do
    nodes=${nodes}\"graphdb-node-$i.graphdb-node:7300\"
    if [ $i -lt $(expr $expectedNodes - 1) ]; then
      nodes=${nodes}\,
    fi
  done
  nodes=\{\"nodes\":\[${nodes}\]\}
  curl -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' --header "Authorization: Basic ${token}" -d "$nodes"  'http://graphdb-cluster-proxy:7200/rest/cluster/config/node'
}

function deleteCluster {
  curl -o response.json -isSL -m 15 -X DELETE --header 'Accept: */*' 'http://graphdb-node-0.graphdb-node:7200/rest/cluster/config?force=false'
  if grep -q 'HTTP/1.1 200' "response.json"; then
    echo "Cluster deletion successful!"
  else if grep -q 'Node is not part of the cluster.\|HTTP/1.1 412' "response.json" ; then
         echo "Node 0 is not part of the cluster"
       else
         echo "Cluster deletion failed, received response:"
         cat response.json
         echo
         exit 1
       fi
  fi
}

function getNodeCountInCurrentCluster {
  local token=$1 --header "Authorization: Basic ${token}"
  local node_address=http://graphdb-node-0.graphdb-node:7200
  waitService "${node_address}/rest/repositories" "$token"
  curl -o clusterResponse.json -isSL -m 15 -X GET --header 'Content-Type: application/json' --header 'Accept: */*' "${node_address}/rest/cluster/config"
  echo `(grep -o 'graphdb-node-' "clusterResponse.json" | grep -c "")`
}

function waitService {
  local address=$1
  local token=$2

  local attempt_counter=0
  local max_attempts=100

  until $(curl --output /dev/null -fsSL -m 5 -H "Authorization: Basic ${token}" --silent --fail ${address}); do
    if [[ ${attempt_counter} -eq ${max_attempts} ]];then
      echo "Max attempts reached"
      exit 1
    fi

    printf '.'
    attempt_counter=$((attempt_counter+1))
    sleep 5
  done
}

"$@"

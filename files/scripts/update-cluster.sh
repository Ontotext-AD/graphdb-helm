#!/usr/bin/env bash

function patchCluster {
  local configLocation=$1
  local token=$2
  echo "Patching cluster"
  waitService "http://graphdb-cluster-proxy:7200/proxy/ready" "$token"
  curl -o patchResponse.json -isSL -m 15 -X PATCH  --header "Authorization: Basic ${token}" --header 'Content-Type: application/json' --header 'Accept: application/json' -d @"$configLocation" 'http://graphdb-cluster-proxy:7200/rest/cluster/config'
    if grep -q 'HTTP/1.1 200' "patchResponse.json"; then
      echo "Patch successful"
    elif grep -q 'Cluster does not exist.\|HTTP/1.1 412' "patchResponse.json" ; then
      echo "Cluster does not exist"
    else
      echo "Cluster patch failed, received response:"
      cat patchResponse.json
      echo
      exit 1
    fi
}

function removeNodes {
  local expectedNodes=$1
  local authToken=$2
  local namespace=$3
  local currentNodes=$(getNodeCountInCurrentCluster "$authToken")
  local nodes=""
# if there is no cluster or current nodes are less or equal to expected so no need to remove more, exit
  if [ "$currentNodes" -lt 2 ] || [ "$currentNodes" -le "$expectedNodes" ]; then
    echo "No scaling required"
    exit 0
  fi
# if there is a cluster and we wanna scale to 1 node, delete it (we would have exit on the last if in case on no cluster)
  if [ "$expectedNodes" -lt 2 ]; then
    echo "Deleting cluster"
    deleteCluster "$authToken"
    exit 0
  fi

  for ((i = expectedNodes; i < currentNodes; i++)) do
    nodes=${nodes}\"graphdb-node-$i.graphdb-node.${namespace}.svc.cluster.local:7300\"
    if [ $i -lt $(expr $currentNodes - 1) ]; then
      nodes=${nodes}\,
    fi
  done
  nodes=\{\"nodes\":\[${nodes}\]\}
  waitService "http://graphdb-cluster-proxy:7200/proxy/ready" "$token"
  curl -o clusterRemove.json -isSL -m 15 -X DELETE --header 'Content-Type: application/json' --header 'Accept: application/json' --header "Authorization: Basic ${token}" -d "${nodes}"  'http://graphdb-cluster-proxy:7200/rest/cluster/config/node'
  if grep -q 'HTTP/1.1 200' "clusterRemove.json"; then
    echo "Scaling down successful."
  else
    echo "Issue scaling down:"
    cat clusterRemove.json
    echo
    exit 1
  fi
}

function addNodes {
  local expectedNodes=$1
  local authToken=$2
  local namespace=$3
  local timeout=$4
  local currentNodes=$(getNodeCountInCurrentCluster "$authToken")
  local nodes=""
# if there is no cluster or current nodes are more or equal to expected so no need to add more, exit
  if [ "$currentNodes" -lt 2 ] || [ "$currentNodes" -ge "$expectedNodes" ]; then
    echo "No scaling required"
    exit 0
  fi
  for ((i = currentNodes; i < expectedNodes; i++)) do
    nodes=${nodes}\"graphdb-node-$i.graphdb-node.${namespace}.svc.cluster.local:7300\"
    if [ $i -lt $(expr $expectedNodes - 1) ]; then
      nodes=${nodes}\,
    fi
  done
  nodes=\{\"nodes\":\[${nodes}\]\}
  waitService "http://graphdb-cluster-proxy:7200/proxy/ready" "$token"
  curl -o clusterAdd.json -isSL -m ${timeout} -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' --header "Authorization: Basic ${token}" -d "${nodes}"  'http://graphdb-cluster-proxy:7200/rest/cluster/config/node'
  if grep -q 'HTTP/1.1 200' "clusterAdd.json"; then
    echo "Scaling successful."
  elif grep -q 'Mismatching fingerprints\|HTTP/1.1 412' "clusterAdd.json"; then
    echo "Issue scaling:"
    cat clusterAdd.json
    echo
    echo "Manual clear of the mismatched repositories will be required to add the node"
    exit 0
  else
    echo "Issue scaling:"
    cat clusterAdd.json
    echo
    exit 1
  fi
}

function deleteCluster {
  local token=$1
  waitService "http://graphdb-node-0.graphdb-node:7200/rest/repositories" "$token"
  curl -o response.json -isSL -m 15 -X DELETE --header "Authorization: Basic ${token}" --header 'Accept: */*' 'http://graphdb-node-0.graphdb-node:7200/rest/cluster/config?force=false'
  if grep -q 'HTTP/1.1 200' "response.json"; then
    echo "Cluster deletion successful!"
  elif grep -q 'Node is not part of the cluster.\|HTTP/1.1 412' "response.json" ; then
    echo "Node 0 is not part of a cluster"
  else
    echo "Cluster deletion failed, received response:"
    cat response.json
    echo
    exit 1
  fi
}

function getNodeCountInCurrentCluster {
  local token=$1
  local node_address=http://graphdb-node-0.graphdb-node:7200
  waitService "${node_address}/rest/repositories" "$token"
  curl -o clusterResponse.json -isSL -m 15 -X GET --header 'Content-Type: application/json' --header "Authorization: Basic ${token}" --header 'Accept: */*' "${node_address}/rest/cluster/config"
  grep -o 'graphdb-node-' "clusterResponse.json" | grep -c ""
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
    attempt_counter=$((attempt_counter+1))
    sleep 5
  done
}

"$@"

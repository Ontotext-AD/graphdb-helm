#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

function patchCluster {
  local configLocation=$1
  local timeout=$2

  echo "Patching cluster"
  waitService "http://${GRAPHDB_PROXY_SERVICE_NAME}:${GRAPHDB_PROXY_SERVICE_PORT}/proxy/ready"
  curl -o patchResponse.json -isSL -m "$timeout" -X PATCH \
       --header "Authorization: Basic ${GRAPHDB_AUTH_TOKEN}" \
       --header 'Content-Type: application/json' \
       --header 'Accept: application/json' \
       -d @"$configLocation" \
       "http://${GRAPHDB_PROXY_SERVICE_NAME}:${GRAPHDB_PROXY_SERVICE_PORT}/rest/cluster/config"

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
  local currentNodes=$(getNodeCountInCurrentCluster)
  local nodes=""
  # DNS suffix in the form of namespace.svc.cluster.local
  local dns_suffix
  dns_suffix=$(awk '/search/{print $2}' /etc/resolv.conf)

  echo "Cluster reported: $currentNodes current nodes"
  echo "Cluster is expected to have: $expectedNodes nodes"

  # if there is no cluster or current nodes are less or equal to expected so no need to remove more, exit
  if [ "$currentNodes" -lt 2 ] || [ "$currentNodes" -le "$expectedNodes" ]; then
    echo "No scaling down of the cluster required"
    exit 0
  fi

  # if there is a cluster and we wanna scale to 1 node, delete it (we would have exit on the last if in case on no cluster)
  if [ "$expectedNodes" -lt 2 ]; then
    echo "Scaling down to 1 node. Deleting cluster"
    deleteCluster
    exit 0
  fi

  echo "Scaling the cluster down"
  for ((i = expectedNodes; i < currentNodes; i++)) do
    nodes=${nodes}\"${GRAPHDB_POD_NAME}-$i.${GRAPHDB_SERVICE_NAME}.${dns_suffix}:${GRAPHDB_SERVICE_RPC_PORT}\"
    if [ $i -lt $(expr $currentNodes - 1) ]; then
      nodes=${nodes}\,
    fi
  done

  nodes=\{\"nodes\":\[${nodes}\]\}
  waitService "http://${GRAPHDB_PROXY_SERVICE_NAME}:${GRAPHDB_PROXY_SERVICE_PORT}/proxy/ready"
  curl -o clusterRemove.json -isSL -m 15 -X DELETE \
       --header 'Content-Type: application/json' \
       --header 'Accept: application/json' \
       --header "Authorization: Basic ${GRAPHDB_AUTH_TOKEN}" \
       -d "${nodes}" \
       "http://${GRAPHDB_PROXY_SERVICE_NAME}:${GRAPHDB_PROXY_SERVICE_PORT}/rest/cluster/config/node"

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
  local timeout=$2
  local currentNodes=$(getNodeCountInCurrentCluster)
  local nodes=""
  # DNS suffix in the form of namespace.svc.cluster.local
  local dns_suffix
  dns_suffix=$(awk '/search/{print $2}' /etc/resolv.conf)

  echo "Cluster reported: $currentNodes current nodes"
  echo "Cluster is expected to have: $expectedNodes nodes"

  # if there is no cluster or current nodes are more or equal to expected so no need to add more, exit
  if [ "$currentNodes" -lt 2 ] || [ "$currentNodes" -ge "$expectedNodes" ]; then
    echo "No scaling up of the cluster required"
    exit 0
  fi

  echo "Scaling the cluster up"
  for ((i = currentNodes; i < expectedNodes; i++)) do
    nodes=${nodes}\"${GRAPHDB_POD_NAME}-$i.${GRAPHDB_SERVICE_NAME}.${dns_suffix}:${GRAPHDB_SERVICE_RPC_PORT}\"
    if [ $i -lt $(expr $expectedNodes - 1) ]; then
      nodes=${nodes}\,
    fi
  done

  nodes=\{\"nodes\":\[${nodes}\]\}
  waitService "http://${GRAPHDB_PROXY_SERVICE_NAME}:${GRAPHDB_PROXY_SERVICE_PORT}/proxy/ready"
  curl -o clusterAdd.json -isSL -m "${timeout}" -X POST \
       --header 'Content-Type: application/json' \
       --header 'Accept: application/json' \
       --header "Authorization: Basic ${GRAPHDB_AUTH_TOKEN}" \
       -d "${nodes}" \
       "http://${GRAPHDB_PROXY_SERVICE_NAME}:${GRAPHDB_PROXY_SERVICE_PORT}/rest/cluster/config/node"

  if grep -q 'HTTP/1.1 200' "clusterAdd.json"; then
    echo "Scaling successful."
  elif grep -q 'Mismatching fingerprints\|HTTP/1.1 412' "clusterAdd.json"; then
    echo "Issue scaling:"
    cat clusterAdd.json
    echo
    echo "Manual clear of the mismatched repositories will be required to add the node"
    exit 1
  else
    echo "Issue scaling:"
    cat clusterAdd.json
    echo
    exit 1
  fi
}

function deleteCluster {
  waitService "http://${GRAPHDB_POD_NAME}-0.${GRAPHDB_SERVICE_NAME}:${GRAPHDB_SERVICE_PORT}/rest/repositories"

  curl -o response.json -isSL -m 15 -X DELETE \
       --header "Authorization: Basic ${GRAPHDB_AUTH_TOKEN}" \
       --header 'Accept: */*' \
       "http://${GRAPHDB_POD_NAME}-0.${GRAPHDB_SERVICE_NAME}:${GRAPHDB_SERVICE_PORT}/rest/cluster/config?force=false"

  if grep -q 'HTTP/1.1 200' "response.json"; then
    echo "Cluster deletion successful!"
  elif grep -q 'Node is not part of the cluster.\|HTTP/1.1 412' "response.json" ; then
    echo "No cluster present."
  else
    echo "Cluster deletion failed, received response:"
    cat response.json
    echo
    exit 1
  fi
}

function getNodeCountInCurrentCluster {
  local node_address="http://${GRAPHDB_POD_NAME}-0.${GRAPHDB_SERVICE_NAME}:${GRAPHDB_SERVICE_PORT}"
  waitService "${node_address}/rest/repositories"
  curl -o clusterResponse.json -isSL -m 15 -X GET \
       --header 'Content-Type: application/json' \
       --header "Authorization: Basic ${GRAPHDB_AUTH_TOKEN}" \
       --header 'Accept: */*' \
       "${node_address}/rest/cluster/config"
  grep -o "${GRAPHDB_SERVICE_NAME}" "clusterResponse.json" | grep -c ""
}

function waitService {
  local address=$1

  local attempt_counter=0
  local max_attempts=100

  until curl --output /dev/null -fsSL -m 5 -H "Authorization: Basic ${GRAPHDB_AUTH_TOKEN}" --silent --fail "${address}"; do
    if [[ ${attempt_counter} -eq ${max_attempts} ]];then
      echo "Max attempts reached"
      exit 1
    fi
    attempt_counter=$((attempt_counter+1))
    sleep 5
  done
}

"$@"

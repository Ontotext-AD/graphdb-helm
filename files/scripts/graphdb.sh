#!/usr/bin/env bash
#TODO: heavy rework required
set -eu

function makeCluster {
  waitAllNodes $1 $2 $3
  echo "Creating cluster!"
  curl -o response.json -sSL -m 5 -X POST --header 'Content-Type: application/json' --header 'Accept: */*' -d @cluster-config.json 'http://graphdb-node-1/rest/cluster/config'
     if grep -q '"status":200' "response.json"; then
        echo "Cluster creation successful!"
    else
        echo "Cluster creation failed, received response:"
        cat response.json
    fi
}

function updateCluster {
#curl to leader/loadBalancer to update cluster
true
}

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

function waitAllNodes {
  local node_count=$1
  local node_repo=$2
  local token=$3

  for (( c=1; c<=$node_count; c++ ))
  do
    local node_address=http://graphdb-node-$c:7200
    waitService "${node_address}/rest/repositories" $token
    waitService "${node_address}/rest/repositories/${node_repo}/size" $token
  done
}

"$@"

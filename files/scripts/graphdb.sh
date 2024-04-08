#!/usr/bin/env bash

set -eu

function createCluster {
  waitAllNodes $1
  local configLocation=$2
  local authToken=$PROVISION_USER_AUTH_TOKEN
  local timeout=$3

  echo "Creating cluster"
  curl -o response.json -isSL -m $timeout -X POST \
       -d @"$configLocation" \
       --header "Authorization: Basic ${authToken}" \
       --header 'Content-Type: application/json' \
       --header 'Accept: */*' \
       "http://${GRAPHDB_POD_NAME}-0.${GRAPHDB_SERVICE_NAME}:${GRAPHDB_SERVICE_PORT}/rest/cluster/config"

  if grep -q 'HTTP/1.1 201' "response.json"; then
    echo "Cluster creation successful!"
  elif grep -q 'Cluster already exists.\|HTTP/1.1 409' "response.json" ; then
    echo "Cluster already exists"
  else
    echo "Cluster creation failed, received response:"
    cat response.json
    echo
    exit 1
  fi
}

function waitService {
  local address=$1
  local authToken=$PROVISION_USER_AUTH_TOKEN

  local attempt_counter=0
  local max_attempts=100

  echo "Waiting for ${address}"
  until $(curl --output /dev/null -fsSL -m 5 -H "Authorization: Basic ${authToken}" --silent --fail ${address}); do
    if [[ ${attempt_counter} -eq ${max_attempts} ]];then
      echo "Max attempts reached"
      exit 1
    fi

    printf '.'
    attempt_counter=$((attempt_counter+1))
    sleep 5
  done
}

function waitAllNodes {
  local node_count=$1

  for (( c=$node_count; c>0; c ))
  do
    c=$((c-1))
    waitService "http://${GRAPHDB_POD_NAME}-$c.${GRAPHDB_SERVICE_NAME}:${GRAPHDB_SERVICE_PORT}/rest/repositories"
  done
}

function createRepositoryFromFile {
  waitAllNodes $1
  local repositoriesConfigsLocation=$2
  local authToken=$PROVISION_USER_AUTH_TOKEN
  local timeout=60
  local success=true

  echo "Creating repositories"
  for filename in ${repositoriesConfigsLocation}/*.ttl; do
    repositoryName=$(grep "rep:repositoryID" $filename | sed -ne 's/rep:repositoryID "//p' | sed -ne 's/" ;//p' | sed -ne 's/^[[:space:]]*//p')

    echo "Provisioning repository ${repositoryName}"
    response=$(
      curl -X POST --connect-timeout 60 --retry 3 --retry-all-errors --retry-delay 10 \
           -F config=@${filename} \
           -H "Authorization: Basic ${authToken}" \
           -H 'Content-Type: multipart/form-data' \
           "http://${GRAPHDB_POD_NAME}-0.${GRAPHDB_SERVICE_NAME}:${GRAPHDB_SERVICE_PORT}/rest/repositories"
    )

    if [ -z "$response" ]; then
      echo "Successfully created repository ${repositoryName}"
    else
      echo "Could not create repository ${repositoryName}, response:"
      echo "$response"
      if ! grep -q "already exists." <<< $response; then
        success=true
      fi
    fi
  done
  if [ $success != true ]; then
    exit 1
  fi
}

"$@"

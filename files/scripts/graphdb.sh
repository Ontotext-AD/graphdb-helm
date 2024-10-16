#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

function log {
    local message="$1"
    local timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] $message"
}

function createCluster {
  local node_count=$1
  local configLocation=$2
  local timeout=$3
  local response

  waitAllNodes "$node_count"

  echo "Creating cluster"
  response=$(mktemp)
  curl -k -o "$response" -isSL -m "${timeout}" -X POST \
       -d @"$configLocation" \
       --header "Authorization: Basic ${GRAPHDB_AUTH_TOKEN}" \
       --header 'Content-Type: application/json' \
       --header 'Accept: */*' \
       "${GRAPHDB_PROTOCOL}://${GRAPHDB_POD_NAME}-0.${GRAPHDB_SERVICE_NAME}:${GRAPHDB_SERVICE_PORT}/rest/cluster/config"

  if grep -q 'HTTP/1.1 201' "$response"; then
    echo "Cluster creation successful!"
  elif grep -q 'Cluster already exists.\|HTTP/1.1 409' "$response" ; then
    echo "Cluster already exists"
  else
    echo "Cluster creation failed, received response:"
    cat "$response"
    echo
    exit 1
  fi
}

function waitService {
  local address=$1

  local attempt_counter=0
  local max_attempts=100

  echo "Waiting for ${address}"
  until curl -k --output /dev/null -fsSL -m 5 -H "Authorization: Basic ${GRAPHDB_AUTH_TOKEN}" --silent --fail "${address}"; do
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

  for (( c=node_count; c>0; c ))
  do
    c=$((c-1))
    waitService "${GRAPHDB_PROTOCOL}://${GRAPHDB_POD_NAME}-$c.${GRAPHDB_SERVICE_NAME}:${GRAPHDB_SERVICE_PORT}/rest/repositories"
  done
}

function createRepositoryFromFile {
  local node_count=$1
  local repositoriesConfigsLocation=$2
  local timeout=60
  local success=true

  waitAllNodes "$node_count"

  echo "Creating repositories"
  for filename in ${repositoriesConfigsLocation}/*.ttl; do
    repositoryName=$(grep "rep:repositoryID" "${filename}" | sed -ne 's/rep:repositoryID "//p' | sed -ne 's/" ;//p' | sed -ne 's/^[[:space:]]*//p')

    echo "Provisioning repository ${repositoryName}"
    response=$(
      curl -k -X POST --connect-timeout 60 --retry 3 --retry-all-errors --retry-delay 10 \
           -F config=@"${filename}" \
           -H "Authorization: Basic ${GRAPHDB_AUTH_TOKEN}" \
           -H 'Content-Type: multipart/form-data' \
           "${GRAPHDB_PROTOCOL}://${GRAPHDB_POD_NAME}-0.${GRAPHDB_SERVICE_NAME}:${GRAPHDB_SERVICE_PORT}/rest/repositories"
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

function interpolate {
  local input=""
  while IFS='' read -r line || [ -n "$line" ]; do
    input="$input$line"$'\n'
  done

  vars=$(echo "${input}" | grep -o "\${[^}]*}" | sed 's/[${}]//g' | uniq)

  local output="$input"
  for var in $vars; do
    value=${!var:-''}
    if [ -n "$value" ]; then
      output=${output//\$\{$var\}/$value}
    fi
  done
  echo "${output}"
}

function cloudBackup {
  BACKUP_TIMESTAMP="$(date +'%Y-%m-%d_%H-%M-%S')"
  BACKUP_NAME="graphdb-backup-${BACKUP_TIMESTAMP}.tar"

  local backup_options=
  backup_options=$(interpolate < "$1")

  log "Creating cloud backup ${BACKUP_NAME}"

  local response=
  local response_status
  response=$(mktemp)
  response_status=$(curl -X POST \
    -isSL \
    -o "${response}" \
    -w "Status=%{response_code}" \
    --header "Authorization: Basic ${GRAPHDB_AUTH_TOKEN}" \
    --header 'Content-Type: application/json' \
    --header 'Accept: application/json' \
    --data-binary "${backup_options}" \
    --url "http://${GRAPHDB_SERVICE_NAME}:${GRAPHDB_SERVICE_PORT}/rest/recovery/cloud-backup")

  if ! echo "${response_status}" | grep -q 'Status=200' ; then
    log "ERROR: Backup ${BACKUP_NAME} creation failed, response: ${response_status}"
    cat "${response}"
    echo ""
    exit 1
  fi

  log "Backup ${BACKUP_NAME} completed successfully!"
}

function localBackup() {
  BACKUP_TIMESTAMP="$(date +'%Y-%m-%d_%H-%M-%S')"
  BACKUP_NAME="graphdb-backup-${BACKUP_TIMESTAMP}.tar"

  local backup_options=
  backup_options=$(interpolate < "$1")

  local backup_path
  backup_path="${2%/}/$BACKUP_NAME"

  log "Creating local backup ${backup_path}"

  local response
  response=$(curl -X POST \
    -sSL \
    -o "${backup_path}" \
    -w "Status=%{response_code}" \
    --header "Authorization: Basic ${GRAPHDB_AUTH_TOKEN}" \
    --header 'Content-Type: application/json' \
    --header 'Accept: application/json' \
    --data-binary "${backup_options}" \
    --url "http://${GRAPHDB_SERVICE_NAME}:${GRAPHDB_SERVICE_PORT}/rest/recovery/backup")

  if ! echo "${response}" | grep -q 'Status=200' ; then
    log "ERROR: Backup ${BACKUP_NAME} creation failed, response: ${response}"
    exit 1
  fi

  log "Backup ${BACKUP_NAME} completed successfully!"
}

"$@"

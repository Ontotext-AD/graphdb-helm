#!/usr/bin/env bash
set -e

function createCluster {
  waitAllNodes $1
  local configLocation=$2
  local authToken=$PROVISION_USER_AUTH_TOKEN
  local timeout=$3
  echo "Creating cluster"
  curl -o response.json -isSL -m $timeout -X POST --header "Authorization: Basic ${authToken}" --header 'Content-Type: application/json' --header 'Accept: */*' -d @"$configLocation" http://graphdb-node-0.graphdb-node:7200/rest/cluster/config
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

function backup {
  local numberOfBackupsToKeep=$1
  local repositories=$2
  local withSystemData=$3
  local authToken=$PROVISION_USER_AUTH_TOKEN
  local repositoriesToBackup="{"
  if [[ $withSystemData = true ]] ; then
    repositoriesToBackup+="\"backupSystemData\": true"
  else
    repositoriesToBackup+="\"backupSystemData\": false"
  fi

  if [[ ${repositories} -ne "" ]] ; then
    repositoriesToBackup+=", \"repositories\": ["
    reposList=(${repositories//,/ })
    for repo in "${reposList[@]}"; do
      repositoriesToBackup+="\"${repo}\","
    done
    repositoriesToBackup=$(echo ${repositoriesToBackup} | sed 's/.$//')
    repositoriesToBackup+="]"
  fi
  repositoriesToBackup+="}"

  numberOfBackups=$(ls /opt/graphdb/backups/ | wc -l)
  echo "Checking count of backups in the backups folder"
  if [[ ${numberOfBackups} -gt ${numberOfBackupsToKeep} ]] ; then
    lastBackupName=$(ls -A1 -h /opt/graphdb/backups/ | head -n1)
    echo "Maximum number of backups will be reached with the current one. Deleting the oldest one named ${lastBackupName}"
    rm /opt/graphdb/backups/${lastBackupName}
  fi
  echo "Starting backup procedure"
  echo "Will backup repositories: ${repositories}"
  echo "Including system data: ${withSystemData}"
  local currentDate=$(date +'%Y-%m-%d-%H-%M')
  echo ${repositoriesToBackup}
  HTTP_CODE=$(curl -X POST --connect-timeout 60 --retry 5 --retry-all-errors --retry-delay 10 -d "${repositoriesToBackup}" --output /opt/graphdb/backups/backup-${currentDate}.tar --header "Authorization: Basic ${authToken}" --header 'Content-Type: application/json' --write-out "%{http_code}" http://graphdb-node-0.graphdb-node:7200/rest/recovery/backup)
  if [[ ${HTTP_CODE} -ne 200 ]] ; then
    echo "Backup operation failed! Returned code ${HTTP_CODE}"
    exit 1
  else
    ln -sf ./backup-${currentDate}.tar /opt/graphdb/backups/backup-latest.tar
    echo "Backup created successfully! Located in /opt/graphdb/backups/backup-${currentDate}.tar, also available as backup-latest.tar"
    exit 0
  fi
}

function backupCloud {
  local backupPath=$1
  local repositories=$2
  local withSystemData=$3
  local authToken=$PROVISION_USER_AUTH_TOKEN

  local repositoriesToBackup="{ \"backupOptions\": {"
  if [[ $withSystemData = true ]] ; then
    repositoriesToBackup+="\"backupSystemData\": true"
  else
    repositoriesToBackup+="\"backupSystemData\": false"
  fi

  if [[ -n "${repositories}" ]]; then
    repositoriesToBackup+=", \"repositories\": ["
    reposList=(${repositories//,/ })
    for repo in "${reposList[@]}"; do
      repositoriesToBackup+="\"${repo}\","
    done
    repositoriesToBackup=$(echo ${repositoriesToBackup} | sed 's/.$//')
    repositoriesToBackup+="]"
  fi

  local region=$REGION
  local awsAccessKeyId=$AWS_ACCESS_KEY_ID
  local awsSecret=$AWS_SECRET_ACCESS_KEY
  local currentDate=$(date +'%Y-%m-%d-%H-%M')

  repositoriesToBackup+="}, \"bucketUri\": \"s3:///${backupPath}/graphdb-backup-${currentDate}.tar?region=${region}&AWS_ACCESS_KEY_ID=${awsAccessKeyId}&AWS_SECRET_ACCESS_KEY=${awsSecret}\" }"

  echo "Starting backup procedure"
  echo "Will backup repositories: ${repositories}"
  echo "Including system data: ${withSystemData}"
  response=$(curl -X POST --connect-timeout 60 --retry 5 --retry-all-errors --retry-delay 10 -d "${repositoriesToBackup}" --header "Authorization: Basic ${authToken}" --header 'Content-Type: application/json' --write-out "%{http_code}" http://graphdb-node-0.graphdb-node:7200/rest/recovery/cloud-backup)
  if grep -q "200" <<< "$response" ; then
    echo "Backup was successful! Returned response -> ${response}"
    echo "The backup is located in s3:///${backupPath}/graphdb-backup-${currentDate}.tar"
    exit 0
  else
    echo "Backup creation failed! Response was -> ${response}"
    exit 1
  fi
}

function restore {
  local backupName=$1
  local repositories=$2
  local restoreSystemData=$3
  local removeStaleRepositories=$4
  local authToken=$PROVISION_USER_AUTH_TOKEN
  local restoreParams="params={"
  if [[ $restoreSystemData = true ]] ; then
    restoreParams+="\"restoreSystemData\": true"
  else
    restoreParams+="\"restoreSystemData\": false"
  fi

  if [[ $removeStaleRepositories = true ]] ; then
    restoreParams+=", \"removeStaleRepositories\": true"
  else
    restoreParams+=", \"removeStaleRepositories\": false"
  fi

  if [[ ${repositories} -ne "" ]] ; then
    restoreParams+=", \"repositories\": ["
    reposList=(${repositories//,/ })
    for repo in "${reposList[@]}"; do
      restoreParams+="\"${repo}\","
    done
    restoreParams=$(echo ${restoreParams} | sed 's/.$//')
    restoreParams+="]"
  fi
  restoreParams+="}"

  echo "Starting restore procedure"
  echo "Restoring from backup: ${backupName}"
  echo "Will restore repositories: ${repositories}"
  echo "Including system data: ${restoreSystemData}"
  echo "With removing of stale repositories: ${removeStaleRepositories}"

  HTTP_CODE=$(curl -X POST --connect-timeout 60 --retry 5 --retry-all-errors --retry-delay 10 -F "${restoreParams}" -F file=@/opt/graphdb/restore/${backupName} --header "Authorization: Basic ${authToken}" --header 'Content-Type: multipart/form-data' --write-out "%{http_code}" http://graphdb-node-0.graphdb-node:7200/rest/recovery/restore)
  if [[ ${HTTP_CODE} -ne 200 ]] ; then
    echo "Restore operation failed! Returned code ${HTTP_CODE}"
    exit 1
  else
    echo "Restore finished successfully!"
    exit 0
  fi
}

function restoreCloud {
  local backupPath=$1
  local repositories=$2
  local restoreSystemData=$3
  local removeStaleRepositories=$4
  local authToken=$PROVISION_USER_AUTH_TOKEN
  local restoreOptions="{ \"restoreOptions\": {"
  if [[ $restoreSystemData = true ]] ; then
    restoreOptions+="\"restoreSystemData\": true"
  else
    restoreOptions+="\"restoreSystemData\": false"
  fi

  if [[ $removeStaleRepositories = true ]] ; then
    restoreOptions+=", \"removeStaleRepositories\": true"
  else
    restoreOptions+=", \"removeStaleRepositories\": false"
  fi

  if [[ ${repositories} -ne "" ]] ; then
    restoreOptions+=", \"repositories\": ["
    reposList=(${repositories//,/ })
    for repo in "${reposList[@]}"; do
      restoreOptions+="\"${repo}\","
    done
    restoreOptions=$(echo ${restoreOptions} | sed 's/.$//')
    restoreOptions+="]"
  fi

  local region=$REGION
  local awsAccessKeyId=$AWS_ACCESS_KEY_ID
  local awsSecret=$AWS_SECRET_ACCESS_KEY

  restoreOptions+="}, \"bucketUri\": \"s3:///${backupPath}?region=${region}&AWS_ACCESS_KEY_ID=${awsAccessKeyId}&AWS_SECRET_ACCESS_KEY=${awsSecret}\" }"

  echo "Starting restore procedure"
  echo "Restoring from backup located at: ${backupPath}"
  echo "Will restore repositories: ${repositories}"
  echo "Including system data: ${restoreSystemData}"
  echo "With removing of stale repositories: ${removeStaleRepositories}"

  HTTP_CODE=$(curl -X POST --connect-timeout 60 --retry 5 --retry-all-errors --retry-delay 10 -d "${restoreOptions}" --header "Authorization: Basic ${authToken}" --header 'Content-Type: application/json' --write-out "%{http_code}" http://graphdb-node-0.graphdb-node:7200/rest/recovery/cloud-restore)
  if [[ ${HTTP_CODE} -ne 200 ]] ; then
    echo "Restore operation failed! Returned code ${HTTP_CODE}"
    exit 1
  else
    echo "Restore finished successfully!"
    exit 0
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
    local node_address=http://graphdb-node-$c.graphdb-node:7200
    waitService "${node_address}/rest/repositories"
  done
}

function createRepositoryFromFile {
  waitAllNodes $1
  local repositoriesConfigsLocation=$2
  local authToken=$PROVISION_USER_AUTH_TOKEN
  local timeout=60
  echo "Creating repositories"
  local success=true
  for filename in ${repositoriesConfigsLocation}/*.ttl; do
    repositoryName=$(grep "rep:repositoryID" $filename | sed -ne 's/rep:repositoryID "//p' | sed -ne 's/" ;//p' | sed -ne 's/^[[:space:]]*//p')
    echo "Provisioning repository ${repositoryName}"
    response=$(curl -X POST --connect-timeout 60 --retry 3 --retry-all-errors --retry-delay 10 -H "Authorization: Basic ${authToken}" -H 'Content-Type: multipart/form-data' -F config=@${filename}  http://graphdb-node-0.graphdb-node:7200/rest/repositories)
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

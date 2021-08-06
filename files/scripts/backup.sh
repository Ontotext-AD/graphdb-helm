#!/usr/bin/env bash
repo_name=$1
topology=$2

function waitService {
  address=$1

  attempt_counter=0
  max_attempts=10

  echo "Waiting for ${address}"
  until $(curl -sSL --output /dev/null --fail ${address}); do
    if [[ ${attempt_counter} -eq ${max_attempts} ]];then
      echo "Max attempts for ${address} reached"
      exit 1
    fi

    printf '.'
    attempt_counter=$(($attempt_counter+1))
    sleep 5
  done
}

waitService http://graphdb-master-1:7200/rest/repositories/${repo_name}/size

currentDate=$(date +'%Y-%m-%d-%H-%M')
backupDir="${repo_name}-${currentDate}"

i=0
if [ ${topology} == 'standalone' ]
then
  while [ $i -lt 3 ]
  do
    curl -o response.json -sSL -H 'content-type: application/json' -d "{\"type\":\"exec\",\"mbean\":\"com.ontotext:type=OwlimRepositoryManager,name=\\\"Repository (/opt/graphdb/home/data/repositories/$repo_name/storage/)\\\"\",\"operation\":\"createZipBackup\",\"arguments\":[\"$backupDir\"]}" http://graphdb-master-1:7200/jolokia/
    if grep -q '"status":200' "response.json"; then
      echo "Successfully made a backup for repository ${repo_name} in folder ${backupDir}!"
      break
    else
      echo "Curl command failed, response was:"
      cat response.json
      sleep 5
    fi
    i=$((i+1))
  done
else
  while [ $i -lt 3 ]
  do
    curl -o response.json -sSL -H 'content-type: application/json' -d "{\"type\":\"exec\", \"mbean\":\"ReplicationCluster:name=ClusterInfo\/${repo_name}\", \"operation\":\"backup\", \"arguments\":[\"${backupDir}\"]}" http://graphdb-master-1:7200/jolokia/
    if grep -q '"status":200' "response.json"; then
      echo "Successfully made a backup for repository ${repo_name} in folder ${backupDir}!"
      break
    else
      echo "Curl command failed, response was:"
      cat response.json
      sleep 5
    fi
    i=$((i+1))
  done
fi

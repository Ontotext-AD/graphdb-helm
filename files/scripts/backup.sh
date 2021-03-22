#!/usr/bin/env bash
repo_name=$1

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

waitService http://graphdb-master-1:7200/rest/repositories/${repo_name}/size

backupDir=$(date +'%m-%d-%Y-%H-%M')

i=0
while [ $i -lt 3 ]
do
  curl -o response.json -H 'content-type: application/json' -d "{\"type\":\"exec\", \"mbean\":\"ReplicationCluster:name=ClusterInfo\/$repo_name\", \"operation\":\"backup\", \"arguments\":[\"${backupDir}\"]}" http://graphdb-master-1:7200/jolokia/
  if grep -q '"status":200' "response.json"; then
    break
  else
    echo "curl failed"
  fi
  i=$((i+1))
done

#curl -H 'content-type: application/json' -d "{\"type\":\"exec\", \"mbean\":\"ReplicationCluster:name=ClusterInfo\/$repo_name\", \"operation\":\"backup\", \"arguments\":[\"${backupDir}\"]}" http://graphdb-master-1:7200/jolokia/

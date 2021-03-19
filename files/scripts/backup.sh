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

curl -H 'content-type: application/json' -d '{"type":"exec", "mbean":"ReplicationCluster:name=ClusterInfo\/${repo_name}", "operation":"backup", "arguments":[null]}' http://graphdb-master-1:7200/jolokia/

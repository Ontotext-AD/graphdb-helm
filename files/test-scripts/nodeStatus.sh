#!/usr/bin/env bash
#SCRIPTS_HOME=$(dirname $(readlink -f $0))
#. $SCRIPTS_HOME/../scripts/grepFile.sh
. grepFile.sh

function checkNodes_1m_3w() {
  master_repo=$1
  curl -o response.json -H 'content-type: application/json' \
    -d "{\"type\":\"read\",\"mbean\":\"ReplicationCluster:name=ClusterInfo\/${master_repo}\",\"attribute\":\"NodeStatus\"}" \
    http://graphdb.local/graphdb/jolokia/

  for i in {1..3}
  do
    grepFixedPatternFile "[ON] http:\/\/graphdb-worker-$i:7200\/repositories\/test"
    if [ $? == 0 ] ; then
	    echo "Worker $i found!"
    else
      echo "Worker $i not found in response"
  fi
  done
}

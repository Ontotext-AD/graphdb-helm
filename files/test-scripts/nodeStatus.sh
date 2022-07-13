#!/usr/bin/env bash
#SCRIPTS_HOME=$(dirname $(readlink -f $0))
#. $SCRIPTS_HOME/../scripts/grepFile.sh
. grepFile.sh

set -eu

function checkNodes_1m_3w() {
  master_repo=$1
  curl -so response.json -H 'content-type: application/json' \
    -d "{\"type\":\"read\",\"mbean\":\"ReplicationCluster:name=ClusterInfo\/${master_repo}\",\"attribute\":\"NodeStatus\"}" \
    http://graphdb-master-1:7200/jolokia/

  for i in $(seq 1 3)
  do
    grepFixedPatternFile "[ON] http:\/\/graphdb-worker-$i:7200\/repositories\/test"
    if [ $? == 0 ] ; then
	    echo "Worker $i found!"
    else
      echo "Worker $i not found"
    fi
  done
}

function checkNodes_2m_3w_rw_ro() {
  master_repo=$1
  curl -so response.json -H 'content-type: application/json' \
    -d "{\"type\":\"read\",\"mbean\":\"ReplicationCluster:name=ClusterInfo\/${master_repo}\",\"attribute\":\"NodeStatus\"}" \
   http://graphdb-master-1:7200/jolokia/

  for i in $(seq 1 3)
  do
    grepFixedPatternFile "[ON] http:\/\/graphdb-worker-$i:7200\/repositories\/test"
    if [ $? == 0 ] ; then
	    echo "Worker $i found!"
    else
      echo "Worker $i not found"
    fi
  done
}

function checkSyncPeers() {
  master_repo=$1
  ro_master=2

   for i in $(seq 1 2)
  do
    curl -so response.json -H 'content-type: application/json' \
    -d "{\"type\":\"read\",\"mbean\":\"ReplicationCluster:name=ClusterInfo\/${master_repo}\",\"attribute\":\"SyncPeers\"}" \
    http://graphdb-master-$i:7200/jolokia/

    grepFixedPatternFile "http:\/\/graphdb-master-$ro_master:7200\/repositories\/test"
    if [ $? == 0 ] ; then
	    echo "Master $i found!"
    else
      echo "Master $i not found"
    fi
      ro_master=1
  done
}
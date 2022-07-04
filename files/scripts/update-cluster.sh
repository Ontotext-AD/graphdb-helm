#!/usr/bin/env bash

# Required commands:
# 1. Patch the cluster config
#   - take current - curl GET node-0/rest/cluster/config
#   - compare it with one in values.yaml
#   - if different - curl PATCH node-o/rest/cluster/config
#   - else do nothing
# 2. Add/Remove nodes
#   - parse - curl GET node-0/rest/cluster/config for number of nodes
#   - compare with node count in values.yaml
#   - if cluster nodes = 1 do nothing, create cluster would have taken care of such situation
#   - if cluster nodes = values.yaml do nothing
#   ADD
#   - if cluster nodes < values.yaml user - curl post /rest/cluster/config/node to add extra
#   REMOVE
#   - if cluster nodes > values.yaml use - curl DELETE /rest/cluster/config/node to delete extra
#   - if cluster nodes > values.yaml = 1 use - curl DELETE /rest/cluster/config to delete cluster and figure out the services/external proxy situation
#
#
#  POSSIBLE ISSUES:
#  if all nodes need to be ready for a process, solution: - curl GET /rest/cluster/group/status and parse their statuses and count from it
#  if an API requires leader i have no idea in what state the external proxy would be
#
#  After things are done and working merge this script with graphdb.sh

function patchCluster {
  #curl to leader/loadBalancer to patch cluster
  echo "Not implemented yet."
}

function doNothing {
  #do not forget to change scale-up job to use something else
  echo "Not implemented yet."
}

function updateClusterNodes {
  #temporarly for testing scale/patch it by deleting it as a pre-upgrade/pre-rollback, create cluster will take care of the rest... hopefully
  deleteCluster
}

function deleteCluster {
  curl -o response.json -isSL -m 15 -X DELETE --header 'Accept: */*' 'http://graphdb-node:7200/rest/cluster/config?force=false'
  if grep -q 'HTTP/1.1 200' "response.json"; then
    echo "Cluster deletion successful!"
  else
    echo "Cluster deletion failed, received response:"
    cat response.json
    echo
    exit 1
  fi
}

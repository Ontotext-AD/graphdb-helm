#!/usr/bin/env bash

set -eu

function performHealthCheck() {
  path_to_repo=$1
  curl -so response.json http://graphdb.local/graphdb/repositories/"$1"/health

  if grep -q '"status":"green"' "response.json"; then
	  echo "OK!"
  else
    echo "Health check failed"
  fi
}
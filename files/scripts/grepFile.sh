#!/usr/bin/env bash

set -eu

function grepFixedPatternFile() {
  pattern=$1

  if grep -qF "$pattern" "response.json"; then
    :
  else
    echo "Pattern $pattern not found in file"
    exit 1
  fi
}

function grepQuietPatternFile() {
  pattern=$1

  if grep -q "$pattern" "response.json"; then
    :
  else
    echo "Pattern $pattern not found in file"
      exit 1
  fi
}
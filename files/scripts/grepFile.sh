#!/usr/bin/env bash

function grepFixedPatternFile() {
  pattern=$1

  if grep -qF "$pattern" "response.json"; then
    :
  else
    echo "Pattern not found in file"
  fi
}

function grepQuietPatternFile() {
  pattern=$1

  if grep -q "$pattern" "response.json"; then
    :
  else
    echo "Pattern not found in file"
  fi
}
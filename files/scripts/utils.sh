#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

function log {
    local message="$1"
    local timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] $message"
}

function gdb_get_oauth2_token() {
  local client_id="${OAUTH2_CLIENT_ID:-null}"
  local client_secret="${OAUTH2_CLIENT_SECRET:-null}"
  local login_url="${OAUTH2_LOGIN_URL:-null}"
  local scope="${OAUTH2_SCOPE:-null}"

  if [[ -z "${client_id}" || "${client_id}" == "null" ]]; then
    log "OAuth2: missing OAUTH2_CLIENT_ID; falling back to basic auth"
    access_token=1
    return
  fi

  if [[ -z "${client_secret}" || "${client_secret}" == "null" ]]; then
    log "OAuth2: missing OAUTH2_CLIENT_SECRET; falling back to basic auth"
    access_token=1
    return
  fi

  if [[ -z "${login_url}" || "${login_url}" == "null" ]]; then
    log "OAuth2: missing login url; falling back to basic auth"
    access_token=1
    return
  fi

  local token_response

  if [[ -z "${scope}" || "${scope}" == "null" ]]; then
    token_response="$(curl -sS -L -X POST "${login_url}" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      --data-urlencode "client_id=${client_id}" \
      --data-urlencode "client_secret=${client_secret}" \
      --data-urlencode "grant_type=client_credentials" 2>/dev/null || true)"
  else
    token_response="$(curl -sS -L -X POST "${login_url}" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      --data-urlencode "client_id=${client_id}" \
      --data-urlencode "client_secret=${client_secret}" \
      --data-urlencode "scope=${scope}" \
      --data-urlencode "grant_type=client_credentials" 2>/dev/null || true)"
  fi


  local token
  token="$(echo "${token_response}" | grep -Eo 'access_token":"[^"]*' | grep -Eo '[^:"]+[^"].$' | grep -Eo '.*[^"]' || true)"

  if [[ -z "${token}" ]]; then
    local err desc
    err="$(echo "${token_response}" | grep -Eo 'error":"[^"]*' | grep -Eo '[^:"]+[^"].$' | grep -Eo '.*[^"]' || true)"
    desc="$(echo "${token_response}" | grep -Eo 'error_description":"[^"]*' | grep -Eo '[^"]+[^"]$' || true)"
    if [[ -n "${err}" || -n "${desc}" ]]; then
      log "OAuth2: token request failed (${err:-unknown}): ${desc:-no description}"
    else
      log "OAuth2: token request failed (no access_token in response)"
    fi
    access_token=1
    return
  fi

  access_token="${token}"
}

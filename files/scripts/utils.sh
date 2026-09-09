#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

function gdb_get_m2m_token() {
  local client_id="${M2M_CLIENT_ID}"
  local client_secret="${M2M_CLIENT_SECRET}"
  local login_url="${M2M_LOGIN_URL}"
  local scope="${M2M_SCOPE}"

  if [[ -z "${client_id}" || "${client_id}" == "null" ]]; then
    log "M2M: missing M2M_CLIENT_ID; falling back to basic auth"
    echo 1
  fi

  if [[ -z "${client_secret}" || "${client_secret}" == "null" ]]; then
    log "M2M: missing M2M_CLIENT_SECRET; falling back to basic auth"
    echo 1
  fi

  if [[ -z "${scope}" || "${scope}" == "null" ]]; then
    log "M2M: missing scope (M2M_SCOPE or AppConfig key m2m-app-scope); falling back to basic auth"
    echo 1
  fi

  if [[ -z "${login_url}" || "${login_url}" == "null" ]]; then
    log "M2M: missing login url; falling back to basic auth"
    echo 1
  fi

  local token_response
  token_response="$(curl -sS -X POST "${login_url}" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "client_id=${client_id}" \
    --data-urlencode "client_secret=${client_secret}" \
    --data-urlencode "scope=${scope}" \
    --data-urlencode "grant_type=client_credentials" 2>/dev/null || true)"

  local token
  token="$(echo "${token_response}" | jq -r '.access_token // empty' 2>/dev/null || true)"

  if [[ -z "${token}" ]]; then
    local err desc
    err="$(echo "${token_response}" | jq -r '.error // empty' 2>/dev/null || true)"
    desc="$(echo "${token_response}" | jq -r '.error_description // empty' 2>/dev/null || true)"
    if [[ -n "${err}" || -n "${desc}" ]]; then
      log "M2M: token request failed (${err:-unknown}): ${desc:-no description}"
    else
      log "M2M: token request failed (no access_token in response)"
    fi
    echo 1
  fi

  printf '%s' "${token}"
}

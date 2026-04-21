#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

HOSTNAME=${1:?Usage: $0 <hostname> [route] [creds]}
ROUTE=${2:-/namespaces}
CREDS=${3:-}

CURL_ARGS=(-s -o /dev/null -w '%{http_code}\t%{time_total}s')
[[ -n "$CREDS" ]] && CURL_ARGS+=(-u "$CREDS")

LOG="${HOSTNAME}-health.log"

while true; do
  printf "%s\t%s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$(curl "${CURL_ARGS[@]}" "https://${HOSTNAME}${ROUTE}")"
  sleep 2
done | tee -a "$LOG"

#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# ./test-eg.sh goldilocks.pelo.tech /namespaces user:password
HOSTNAME=${1:?Usage: $0 <hostname> [route] [creds]}

ROUTE=${2:-/}
CREDS=${3:-}

NLB_HOSTNAME=$(kubectl get svc -n envoy-gateway-system -o jsonpath='{.items[?(@.spec.type=="LoadBalancer")].status.loadBalancer.ingress[0].hostname}')
NLB_IP=$(dig +short "$NLB_HOSTNAME" | head -1)

echo "NLB: $NLB_HOSTNAME ($NLB_IP)"

CURL_ARGS=(-k --resolve "${HOSTNAME}:443:${NLB_IP}")
[[ -n "$CREDS" ]] && CURL_ARGS+=(-u "$CREDS")

curl "${CURL_ARGS[@]}" -w "\n\nStatus: %{http_code} | Time: %{time_total}s\n" "https://${HOSTNAME}${ROUTE}"

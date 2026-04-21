#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

HOSTNAME=${1:?Usage: $0 <hostname>}

NLB_HOSTNAME=$(kubectl get svc -n envoy-gateway-system -o jsonpath='{.items[?(@.spec.type=="LoadBalancer")].status.loadBalancer.ingress[0].hostname}')
NLB_IPS=$(dig +short "$NLB_HOSTNAME" | sort)
RESOLVED_IPS=$(dig +short "$HOSTNAME" | sort)

echo "EG NLB IPs:       $(echo $NLB_IPS | tr '\n' ' ')"
echo "Resolved IPs:     $(echo $RESOLVED_IPS | tr '\n' ' ')"

if [[ "$NLB_IPS" == "$RESOLVED_IPS" ]]; then
  echo "✓ $HOSTNAME is resolving to EG NLB"
else
  echo "✗ $HOSTNAME is NOT resolving to EG NLB"
  exit 1
fi

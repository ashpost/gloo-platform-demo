#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

## Set environment variables
source env.sh
source chenv.sh

display cluster1
istioctl proxy-status --context ${CLUSTER1}
display cluster2
istioctl proxy-status --context ${CLUSTER2}
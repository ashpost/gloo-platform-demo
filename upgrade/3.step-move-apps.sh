#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

## Set environment variables
source env.sh
source chenv.sh

# Scale the gateways
kubectl get deployments -n istio-gateways --context ${CLUSTER1} -o json | jq -r '.items[].metadata.name' | while read dp; do
  kubectl scale deployment/${dp} -n istio-gateways --replicas=2 --context ${CLUSTER1}
done
kubectl get deployments -n istio-gateways --context ${CLUSTER2} -o json | jq -r '.items[].metadata.name' | while read dp; do
  kubectl scale deployment/${dp} -n istio-gateways --replicas=2 --context ${CLUSTER2}
done
sleep 10

# Restart Pods
kubectl --context ${CLUSTER1} get ns -l istio.io/rev=${OLD_REVISION} -o json | jq -r '.items[].metadata.name' | while read ns; do
  kubectl --context ${CLUSTER1} label ns ${ns} istio.io/rev=${NEW_REVISION} --overwrite
  kubectl --context ${CLUSTER1} -n ${ns} rollout restart deploy
  sleep 2
done

kubectl --context ${CLUSTER2} get ns -l istio.io/rev=${OLD_REVISION} -o json | jq -r '.items[].metadata.name' | while read ns; do
  kubectl --context ${CLUSTER2} label ns ${ns} istio.io/rev=${NEW_REVISION} --overwrite
  kubectl --context ${CLUSTER2} -n ${ns} rollout restart deploy
  sleep 2
done

kubectl --context ${CLUSTER1} -n httpbin patch deploy in-mesh --patch "{\"spec\": {\"template\": {\"metadata\": {\"labels\": {\"istio.io/rev\": \"${NEW_REVISION}\" }}}}}"

sleep 10
istioctl proxy-status --context ${CLUSTER1}
istioctl proxy-status --context ${CLUSTER2}
















# kubectl --context ${CLUSTER1} label ns bookinfo-frontends istio.io/rev=${NEW_REVISION} --overwrite
# kubectl --context ${CLUSTER1} -n bookinfo-frontends rollout restart deploy
# kubectl --context ${CLUSTER1} label ns bookinfo-backends istio.io/rev=${NEW_REVISION} --overwrite
# kubectl --context ${CLUSTER1} -n bookinfo-backends rollout restart deploy

# kubectl --context ${CLUSTER2} label ns bookinfo-frontends istio.io/rev=${NEW_REVISION} --overwrite
# kubectl --context ${CLUSTER2} -n bookinfo-frontends rollout restart deploy
# kubectl --context ${CLUSTER2} label ns bookinfo-backends istio.io/rev=${NEW_REVISION} --overwrite
# kubectl --context ${CLUSTER2} -n bookinfo-backends rollout restart deploy


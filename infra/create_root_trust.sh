#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Set environment variables
source env.sh
# Get deployed istio revision
export REVISION=$(kubectl get pod -L app=istiod -n istio-system --context $REMOTE_CONTEXT1 -o jsonpath='{.items[0].metadata.labels.istio\.io/rev}')
display $REVISION

# Create Root Trust Policy to allow end-to-end mTLS cross cluster communication. This will ensure that certificates issues by istiod on each cluster are signed with intermediate certs which have a common root CA

kubectl apply --context ${MGMT} -f - <<EOF
apiVersion: admin.gloo.solo.io/v2
kind: RootTrustPolicy
metadata:
  name: root-trust-policy
  namespace: gloo-mesh
spec:
  config:
    mgmtServerCa:
      generated: {}
    autoRestartPods: false # Restarting pods automatically is NOT RECOMMENDED in Production
EOF

# When RootTrustPolicy is created, Gloo Mesh kicks off the process of unifying identities under a shared root
# First Gloo Mesh will create a Root Cert
# then GM will use agent on each cluster to create new key/cert pair that will form an ICA used by mesh on that cluster.

sleep 120
# Restart the components
kubectl rollout restart deploy/istiod-${REVISION} --context ${CLUSTER1} -n istio-system
kubectl rollout restart deploy/istiod-${REVISION} --context ${CLUSTER2} -n istio-system

sleep 120
istioctl pc secrets deploy/istio-eastwestgateway-${REVISION} -n istio-gateways --context ${CLUSTER1}
istioctl pc secrets deploy/istio-eastwestgateway-${REVISION} -n istio-gateways --context ${CLUSTER2}

# Restart Pods
kubectl --context ${CLUSTER1} get ns -l istio.io/rev=${REVISION} -o json | jq -r '.items[].metadata.name' | while read ns; do
  kubectl --context ${CLUSTER1} -n ${ns} rollout restart deploy
  sleep 2
done

kubectl --context ${CLUSTER2} get ns -l istio.io/rev=${REVISION} -o json | jq -r '.items[].metadata.name' | while read ns; do
  kubectl --context ${CLUSTER2} -n ${ns} rollout restart deploy
  sleep 2
done

istioctl pc secrets deploy/istio-eastwestgateway-${REVISION} -n istio-gateways --context ${CLUSTER1}
istioctl pc secrets deploy/istio-eastwestgateway-${REVISION} -n istio-gateways --context ${CLUSTER2}

cluster1ca=$(istioctl pc secrets deploy/istio-eastwestgateway-1-17-2 -n istio-gateways --context ${CLUSTER1} | grep ROOTCA | awk '{print $5}')
cluster2ca=$(istioctl pc secrets deploy/istio-eastwestgateway-1-17-2 -n istio-gateways --context ${CLUSTER2} | grep ROOTCA | awk '{print $5}')

if [[ $cluster1ca != $cluster2ca ]]; then
    display "ROOTCAs are not same; do something"
fi
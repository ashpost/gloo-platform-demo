#!/bin/bash

# Set environment variables
source env.sh
# Get deployed istio revision
export REVISION=$(kubectl get pod -L app=istiod -n istio-system --context $REMOTE_CONTEXT1 -o jsonpath='{.items[0].metadata.labels.istio\.io/rev}')
display $REVISION

cluster1ca=$(istioctl pc secrets deploy/istio-eastwestgateway-${REVISION} -n istio-gateways --context ${CLUSTER1} | grep ROOTCA | awk '{print $5}')
cluster2ca=$(istioctl pc secrets deploy/istio-eastwestgateway-${REVISION} -n istio-gateways --context ${CLUSTER2} | grep ROOTCA | awk '{print $5}')

if [[ $cluster1ca != $cluster2ca ]]; then
    display "ROOTCAs are not same; do something"
    exit
fi

# App Install
./apps/5.bookinfo_install.sh
sleep 20
./apps/6.httpbin_install.sh
sleep 20
./apps/7.workspace_setup.sh
sleep 20
./apps/8.bookinfo_expose.sh
sleep 20
./apps/setup_vd.sh
sleep 20
./apps/httpbin_workspace.sh
sleep 20
./apps/httpbin_expose.sh

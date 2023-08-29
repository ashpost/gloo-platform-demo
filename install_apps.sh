#!/bin/bash


cluster1ca=$(istioctl pc secrets deploy/istio-eastwestgateway-1-17-2 -n istio-gateways --context ${CLUSTER1} | grep ROOTCA | awk '{print $5}')
cluster2ca=$(istioctl pc secrets deploy/istio-eastwestgateway-1-17-2 -n istio-gateways --context ${CLUSTER2} | grep ROOTCA | awk '{print $5}')

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

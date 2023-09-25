#!/bin/bash

source env.sh

cluster1ca=$(istioctl pc secrets deploy/istio-eastwestgateway-${REVISION} -n istio-gateways --context ${CLUSTER1} | grep ROOTCA | awk '{print $5}')
cluster2ca=$(istioctl pc secrets deploy/istio-eastwestgateway-${REVISION} -n istio-gateways --context ${CLUSTER2} | grep ROOTCA | awk '{print $5}')

cowsay "${CLUSTER1} ${cluster1ca}"
cowsay "${CLUSTER2} ${cluster2ca}"

if [[ $cluster1ca != $cluster2ca ]]; then
    display "ROOTCAs are not equal; do something"
    exit
fi

display ${cluster1ca}
display ${cluster2ca}

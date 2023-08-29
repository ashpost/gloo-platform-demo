#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

function install_clusters() {

    colima start --cpu 4 --memory 8 --kubernetes --kubernetes-disable traefik -p mgmt --network-address
    colima start --cpu 4 --memory 8 --kubernetes --kubernetes-disable traefik -p cluster1 --network-address
    colima start --cpu 4 --memory 8 --kubernetes --kubernetes-disable traefik -p cluster2 --network-address

    kubectl ctx mgmt=colima-mgmt
    kubectl ctx cluster1=colima-cluster1
    kubectl ctx cluster2=colima-cluster2

    sleep 5
    kubectl --context cluster1 label nodes --all topology.kubernetes.io/region=sydney --overwrite
    kubectl --context cluster2 label nodes --all topology.kubernetes.io/region=melb --overwrite

    kubectl config use-context mgmt
}

install_clusters


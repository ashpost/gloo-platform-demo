#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

source env.sh

function install_clusters() {
    eksctl create cluster --name mgmt --nodes 3 --region ${CA_REGION}
    eksctl create cluster --name cluster1 --nodes 3 --region ${CA_REGION}
    eksctl create cluster --name cluster2 --nodes 3 --region ${CA_REGION}

    kubectl ctx mgmt=Administrator@mgmt.${CA_REGION}.eksctl.io
    kubectl ctx cluster1=Administrator@cluster1.${CA_REGION}.eksctl.io
    kubectl ctx cluster2=Administrator@cluster2.${CA_REGION}.eksctl.io

    sleep 5

    kubectl config use-context mgmt
}

install_clusters


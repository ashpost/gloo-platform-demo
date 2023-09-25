#!/bin/bash

# Set environment variables
export GLOO_VERSION="2.4"

# Set Contexts
export MGMT=mgmt
export REMOTE_CONTEXT1=cluster1
export CLUSTER1=cluster1
export REMOTE_CONTEXT2=cluster2
export CLUSTER2=cluster2


export CA_REGION=ap-southeast-2

export REPO=$GLOO_REPO_KEY
export ISTIO_IMAGE=1.18.2-solo
export REVISION=1-18-2

# create_ns context namespace
function create_ns () {
    if [ ! $(kubectl --context $1 get ns | grep $2) ]; then
        kubectl --context $1 create ns $2
    else
        echo "Namespace $2 already exists"
    fi
}

function display () {
    echo
    echo "###########################################################"
    echo " $@"
    echo "###########################################################"
}

wait_for_lb_address() {
    local context=$1
    local service=$2
    local ns=$3
    ip=""
    while [ -z $ip ]; do
        echo "Waiting for $service external IP ..."
        ip=$(kubectl --context ${context} -n $ns get service/$service --output=jsonpath='{.status.loadBalancer}' | grep "ingress")
        [ -z "$ip" ] && sleep 5
    done
    echo "Found $service external IP: ${ip}"
}

#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

## Set environment variables
source env.sh

ARGOCD_VERSION="5.46.3"

install_argocd () {
    helm repo add argo https://argoproj.github.io/argo-helm
    helm repo update argo

    helm install argocd argo/argo-cd -n gitops \
        --kube-context=${MGMT} \
        --version ${ARGOCD_VERSION} \
        --create-namespace \
        -f integrations/argocd-helm-values.yaml

    kubectl --context ${MGMT} -n gitops wait deploy/argocd-server --for condition=Available=True --timeout=90s

    wait_for_lb_address ${MGMT} "argocd-server" "gitops"
}

install_argocd
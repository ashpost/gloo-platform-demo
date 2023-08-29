#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

## Set environment variables
source env.sh
source chenv.sh

function upgrade_istio() {
  id=$1

  kubectl apply --context ${MGMT} -f - <<EOF
apiVersion: admin.gloo.solo.io/v2
kind: IstioLifecycleManager
metadata:
  name: ${CLUSTER}-installation
  namespace: gloo-mesh
spec:
  installations:
    - clusters:
      - name: ${CLUSTER}
        defaultRevision: false
      revision: ${OLD_REVISION}
      istioOperatorSpec:
        profile: minimal
        hub: ${REPO}
        tag: ${ISTIO_IMAGE}
        namespace: istio-system
        values:
          global:
            meshID: mesh${id}
            multiCluster:
              clusterName: ${CLUSTER}
            network: ${CLUSTER}
        meshConfig:
          accessLogFile: /dev/stdout
          defaultConfig:        
            proxyMetadata:
              ISTIO_META_DNS_CAPTURE: "true"
              ISTIO_META_DNS_AUTO_ALLOCATE: "true"
        components:
          pilot:
            k8s:
              env:
                - name: PILOT_ENABLE_K8S_SELECT_WORKLOAD_ENTRIES
                  value: "false"
          ingressGateways:
          - name: istio-ingressgateway
            enabled: false
    - clusters:
      - name: ${CLUSTER}
        defaultRevision: true
      revision: ${NEW_REVISION}
      istioOperatorSpec:
        profile: minimal
        hub: ${REPO}
        tag: ${NEW_ISTIO_IMAGE}
        namespace: istio-system
        values:
          global:
            meshID: mesh${id}
            multiCluster:
              clusterName: ${CLUSTER}
            network: ${CLUSTER}
        meshConfig:
          accessLogFile: /dev/stdout
          defaultConfig:        
            proxyMetadata:
              ISTIO_META_DNS_CAPTURE: "true"
              ISTIO_META_DNS_AUTO_ALLOCATE: "true"
        components:
          pilot:
            k8s:
              env:
                - name: PILOT_ENABLE_K8S_SELECT_WORKLOAD_ENTRIES
                  value: "false"
          ingressGateways:
          - name: istio-ingressgateway
            enabled: false
EOF
}

export CLUSTER=$CLUSTER1
upgrade_istio 1
export CLUSTER=$CLUSTER2
upgrade_istio 2

sleep 10

kubectl --context ${MGMT} -n gloo-mesh get istiolifecyclemanager.admin.gloo.solo.io -ojsonpath='{.items[*].status.clusters.*.installations.*}'|jq -r '[.observedOperator.components.ingressGateways[].label, .observedRevision, .state]'

kubectl --context ${MGMT} -n gloo-mesh get gatewaylifecyclemanagers.admin.gloo.solo.io -ojsonpath='{.items[*].status.clusters.*.installations.*}'|jq -r '[.observedOperator.components.ingressGateways[].label, .observedRevision, .state]'

istioctl proxy-status --context ${CLUSTER1}
istioctl proxy-status --context ${CLUSTER2}
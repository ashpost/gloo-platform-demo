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

  kubectl apply --context ${MGMT} -f - <<EOF
apiVersion: admin.gloo.solo.io/v2
kind: GatewayLifecycleManager
metadata:
  name: ${CLUSTER}-ingress
  namespace: gloo-mesh
spec:
  installations:
    - clusters:
      - name: ${CLUSTER}
        activeGateway: true
      gatewayRevision: ${NEW_REVISION}
      istioOperatorSpec:
        profile: empty
        hub: ${REPO}
        tag: ${NEW_ISTIO_IMAGE}
        values:
          gateways:
            istio-ingressgateway:
              customService: true
        components:
          ingressGateways:
            - name: istio-ingressgateway
              namespace: istio-gateways
              enabled: true
              label:
                istio: ingressgateway
---
apiVersion: admin.gloo.solo.io/v2
kind: GatewayLifecycleManager
metadata:
  name: ${CLUSTER}-eastwest
  namespace: gloo-mesh
spec:
  installations:
    - clusters:
      - name: ${CLUSTER}
        activeGateway: false
      gatewayRevision: ${NEW_REVISION}
      istioOperatorSpec:
        profile: empty
        hub: ${REPO}
        tag: ${NEW_ISTIO_IMAGE}
        values:
          gateways:
            istio-ingressgateway:
              customService: true
        components:
          ingressGateways:
            - name: istio-eastwestgateway
              namespace: istio-gateways
              enabled: true
              label:
                istio: eastwestgateway
                topology.istio.io/network: ${CLUSTER}
              k8s:
                env:
                  - name: ISTIO_META_ROUTER_MODE
                    value: "sni-dnat"
                  - name: ISTIO_META_REQUESTED_NETWORK_VIEW
                    value: ${CLUSTER}
EOF
}

export CLUSTER=$CLUSTER1
upgrade_istio 1
export CLUSTER=$CLUSTER2
upgrade_istio 2

sleep 5
kubectl --context ${CLUSTER1} -n istio-system get pods && kubectl --context ${CLUSTER1} -n istio-gateways get pods
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
kind: GatewayLifecycleManager
metadata:
  name: ${CLUSTER}-ingress
  namespace: gloo-mesh
spec:
  installations:
    - clusters:
      - name: ${CLUSTER}
        activeGateway: false
      gatewayRevision: ${OLD_REVISION}
      istioOperatorSpec:
        profile: empty
        hub: ${REPO}
        tag: ${ISTIO_IMAGE}
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
      gatewayRevision: ${OLD_REVISION}
      istioOperatorSpec:
        profile: empty
        hub: ${REPO}
        tag: ${ISTIO_IMAGE}
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

# Switch to istio gateway corresponding to the new revision
kubectl --context ${CLUSTER} -n istio-gateways patch svc istio-ingressgateway --patch "{\"spec\": {\"selector\": {\"revision\": \"${NEW_REVISION}\" }}}"
kubectl --context ${CLUSTER} -n istio-gateways patch svc istio-eastwestgateway --patch "{\"spec\": {\"selector\": {\"revision\": \"${NEW_REVISION}\" }}}"
}

export CLUSTER=$CLUSTER1
upgrade_istio 1
export CLUSTER=$CLUSTER2
upgrade_istio 2

sleep 5

kubectl --context ${MGMT} -n gloo-mesh get istiolifecyclemanager.admin.gloo.solo.io -ojsonpath='{.items[*].status.clusters.*.installations.*}'|jq -r '[.observedOperator.components.ingressGateways[].label, .observedRevision, .state]'

kubectl --context ${MGMT} -n gloo-mesh get gatewaylifecyclemanagers.admin.gloo.solo.io -ojsonpath='{.items[*].status.clusters.*.installations.*}'|jq -r '[.observedOperator.components.ingressGateways[].label, .observedRevision, .state]'

sleep 3
istioctl proxy-status --context ${CLUSTER1}
istioctl proxy-status --context ${CLUSTER2}

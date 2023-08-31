#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

## Set environment variables
source env.sh
# Get deployed istio revision
export REVISION=$(kubectl get pod -L app=istiod -n istio-system --context $REMOTE_CONTEXT1 -o jsonpath='{.items[0].metadata.labels.istio\.io/rev}')
display $REVISION

kubectl delete svc istio-ingressgateway -n istio-gateways --context ${CLUSTER1}

sleep 3

kubectl apply --context ${CLUSTER1} -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  labels:
    app: istio-ingressgateway
    istio: ingressgateway
  name: istio-ingressgateway
  namespace: istio-gateways
spec:
  ports:
  - name: http2
    port: 80
    protocol: TCP
    targetPort: 8080
  - name: https
    port: 443
    protocol: TCP
    targetPort: 8443
  - name: status-port
    port: 15021
    protocol: TCP
    targetPort: 15021
  selector:
    app: istio-ingressgateway
    istio: ingressgateway
    revision: ${REVISION}
  type: LoadBalancer
EOF

kubectl apply --context ${CLUSTER1} -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/healthcheck-path: /healthz/ready
    alb.ingress.kubernetes.io/healthcheck-port: traffic-port
    alb.ingress.kubernetes.io/backend-protocol: HTTP
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}]'
  name: gw-ingress
  namespace: istio-gateways
spec:
  rules:
  - http:
      paths:      
      - backend:
          service:
            name: istio-ingressgateway
            port: 
              number: 15021
        path: /healthz/ready
        pathType: Prefix
      - backend:
          service:
            name: istio-ingressgateway
            port: 
              number: 80
        path: /
        pathType: Prefix
EOF
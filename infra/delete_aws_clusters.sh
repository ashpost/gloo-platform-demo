#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

source env.sh

function delete_clusters() {
    
    display "Deleting Cluster ${CLUSTER1}"
    eksctl delete cluster --name ${CLUSTER1} --region ${CA_REGION} --wait
    display "Deleting Cluster ${CLUSTER2}"
    eksctl delete cluster --name ${CLUSTER2} --region ${CA_REGION} --wait
    display "Deleting Cluster ${MGMT}"
    eksctl delete cluster --name ${MGMT} --region ${CA_REGION} --wait
}

#kubectl delete ing gw-ingress -n istio-gateways  --context ${CLUSTER1} --wait

#kubectl delete svc istio-ingressgateway -n istio-gateways --wait

#display "Deleting iamserviceaccount"
#eksctl delete iamserviceaccount aws-load-balancer-controller --cluster ${CLUSTER1}

#POLICY_ARN=$(aws iam list-policies --region ${CA_REGION} --output table | grep ${CLUSTER1} | awk '{print $2}')
#display ${POLICY_ARN}
# Detach Role
#aws iam delete-policy --policy-arn ${POLICY_ARN}


sleep 5
delete_clusters

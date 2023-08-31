#!/bin/bash
#set -euo pipefail
#IFS=$'\n\t'

# Set environment variables
source env.sh

###############################################################################
# As per https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html
# Your cluster has an OIDC issuer URL associated with it. To use AWS IAM roles
# for service accounts, an IAM OIDC provider must exist
# Step 1: Create an IAM OIDC provider for cluster
###############################################################################
eksctl utils associate-iam-oidc-provider \
    --region ${CA_REGION} \
    --cluster ${CLUSTER1} \
    --approve

###############################################################################
# Download IAM Policy for AWS Load Balancer Controller that allows it to make
# calls to AWs APIs on your behalf
###############################################################################
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.5.4/docs/install/iam_policy.json

###############################################################################
# Create IAM policy using downloaded controller policy
###############################################################################
POLICY_ARN=$(aws iam create-policy \
    --policy-name ${CLUSTER1}-AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json \
    --output json | jq -r '.Policy.Arn')
display "POLICY_ARN=${POLICY_ARN}"

###############################################################################
# Get arn from above command
# arn:aws:iam::941622571599:policy/ash-AWSLoadBalancerControllerIAMPolicy
# PolicyId: ANPA5WPIUGJH7IFE74K7T
###############################################################################

display "Creating iamserviceaccount for cluster ${CLUSTER1}"
eksctl create iamserviceaccount \
    --cluster=${CLUSTER1} \
    --namespace=kube-system \
    --name=aws-load-balancer-controller \
    --attach-policy-arn=${POLICY_ARN} \
    --override-existing-serviceaccounts \
    --region ${CA_REGION} \
    --approve

###############################################################################
# Now install the controller
###############################################################################
helm repo add eks https://aws.github.io/eks-charts
helm repo update eks
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
    --kube-context ${CLUSTER1} \
    -n kube-system \
    --set clusterName=${CLUSTER1} \
    --set serviceAccount.create=false \
    --set serviceAccount.name=aws-load-balancer-controller \
    --set replicaCount=1

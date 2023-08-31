# Gloo Platform Canary Upgrade
This repo showcases how to install Gloo Platform and then perform a canary upgrade on the platform

## Infrastructure Installation
This command will create clusters, install gloo platform as well istio on workload clusters
`./install_infra.sh` to create clusters.

## App Installation
To install bookinfo and httpbin apps
`./install_apps.sh` to create clusters.

## Istio Canary Upgrade
Istio Canary Upgrade is a detailed 5 step process
1. Install the new version of istio
   ```./upgrade/1.step-install-new.sh```
2. Make new version the active version using IstioLifeCycleManager
   ```./upgrade/2.step-to-new-istio.sh```
3. Move apps and gateways to the new control plane
   ```./upgrade/3.step-move-apps.sh```
4. Make new gateway, the active gateway
    ```./upgrade/4.step-to-new-gws.sh```

## Cleanup
Once new version is up and running, remove the old control plane, gateways, istio operator etc
```./upgrade/5.step-remove-old.sh```


# For AWS
First setup kubeconfigs

```
kubectl config rename-context Administrator@mgmt.ap-southeast-2.eksctl.io mgmt
kubectl config rename-context Administrator@cluster1.ap-southeast-2.eksctl.io cluster1
kubectl config rename-context Administrator@cluster2.ap-southeast-2.eksctl.io cluster2
```


### [***OPTIONAL***] Only if clusters do not already exists

`./infra/create_aws_clusters.sh`

### Start installing the Gloo Platform 

```./infra/2.mesh_install.sh```

### Register both workload clusters

```./infra/3.register_clusters.sh```

### Install istio control plane

```./infra/4.istio_install.sh```

### Setup AWS LB Controller on Cluster 1

```./infra/setup-lb-controller.sh```

### Create ingress and servcie for ALB (*This will take some time*)

```./infra/alb-service.sh```

If you are provisioning NLB then use 

`./infra/nlb-service.sh`

### Finally Create Root Trust Policy

```./infra/create_root_trust.sh```


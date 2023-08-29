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

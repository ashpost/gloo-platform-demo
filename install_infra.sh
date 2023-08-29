#!/bin/bash

## Infra Install
# First create clusters
./infra/1.create_clusters.sh
sleep 20
# Install Management Plane
./infra/2.mesh_install.sh
sleep 20
# Register Clusters
./infra/3.register_clusters.sh
sleep 20
# Install Istio
./infra/4.istio_install.sh
sleep 120
# Create Root Trust Policy
./infra/create_root_trust.sh

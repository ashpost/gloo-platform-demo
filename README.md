# Gloo Mesh Install

1. `./infra/1.create_cluster.sh` to create clusters. This can be replaced by cluster creation based on cloud
2. `./infra/2.mesh_install.sh`
3. `./infra/3.register_cluster.sh`
4. `./infra/4.istio_install.sh`
5. `./infra/create_root_trust.sh`
6. `./apps/5.bookinfo_install.sh`
7. `./apps/6.httpbin_install.sh`
8.  `./apps/7.workspace_setup.sh`
9.  `./apps/8.bookinfo_expose.sh`
10. `./apps/setup_vd.sh`
11. `./apps/httpbin_workspace.sh`
12. `./apps/httpbin_expose.sh`
13. `extauth/setup_apikey.sh` to setup API key authentication on httpbin workspace
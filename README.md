# GDS Supported Platform - Teams

Persistant cluster configurations for GDS teams using the GDS Supported Platform.

## Setting a deployer pipeline

Pipelines are not currently continuously deployed and must be manually updated.

To update a pipeline for one of the cluster configurations listed in [./clusters/](./clusters) can use the following script:

```sh
CLUSTER_NAME=sandbox ./hack/set-pipeline.sh
```

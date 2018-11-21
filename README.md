# Government Shared Platform (come up with a better name please) - Teams

...

## Prerequisites

- Docker installed and running locally

## How to register a new cluster

1. Manualy `Create Bucket` in the Service Team's AWS account
    * `Bucket name` should resolve to
      `gds-re-${AWS_ACCOUNT_NAME}-terraform-state`
    * `Versioning` should be opt in
    * `Default encryption` should be opt in
1. Manualy `Create Hosted Zone` in the Service Team's AWS account
    * `Domain Name` should resolve to
      `${AWS_ACCOUNT_NAME}.${CLOUD}.ext.govsvc.uk`
    * `Type` should be set to `Public Hosted Zone`
    * Take a note of:
        * `Hosted Zone ID`
        * `Domain Name`
        * Zone's `NS` record type values
1. In the `run-production` AWS account, `Create Record Set` in the already
   existing Hosted Zone
   * `Name` field needs to match the `Domain Name` from the previous step
   * `Type` field needs to be set to `NS - Name Server`
   * `Value` field needs to contain the `NS` records obtained from the Service
     Team's AWS account
1. Create cluster

    From this point onwards, you will need some environment variables defined:

    | Variable | Description | Example |
    |---|---|---|
    | `AWS_ACCOUNT_NAME` | This should match your AWS account name or the account ID. | `re-managed-observe-production` |
    | `AWS_REGION` | Should represent AWS region. Stick to London. | `eu-west-2` |
    | `CLUSTER_NAME` | The name of the cluster about to be created. Needs to be unique across your entire Hosted Zone. | `cluster1` |
    | `ZONE_ID` | An AWS Hosted Zone ID which you've obtained from the first step of this guide. | `Z00000000000` |
    | `ZONE_NAME` | An AWS Hosted Zone name which you've obtained from the first step of this guide. | `re-managed-observe-production.aws.ext.govsvc.uk` |
    | `MAIN_PASSWORD` | The password for the Concourse `admin` user created by the script. | `pwgen 40 1` |

    We've prepared a templater script to create the new cluster terraform
    declaration.

    With the above variables you can run:

    ```sh
    ./scripts/create_cluster_config.sh
    ```

    This should generate new file at the location:

    ```
    terraform/clusters/cluster1.gds-re-run-production.aws.ext.govsvc.uk/cluster.tf
    ```

    Pull in the gsp-base sub-module:
    ```
    git submodule init
    git submodule update
    ```

    This leaves you with a manual step of:

    ```sh
    export DOMAIN=cluster1.gds-re-run-production.aws.ext.govsvc.uk
    cd terraform/clusters/${DOMAIN}
    aws-vault exec run-production -- docker run -it --env AWS_DEFAULT_REGION --env AWS_REGION --env AWS_ACCESS_KEY_ID --env AWS_SECRET_ACCESS_KEY --env AWS_SESSION_TOKEN --env AWS_SECURITY_TOKEN --env DOMAIN --volume=$(pwd)/../../../:/terraform -w /terraform/terraform/clusters/${DOMAIN} govsvc/terraform {init, plan, apply} -var-file=secrets.tfvars
    ```

1. Test the connection to Kubernetes by executing the following:
    ```
    export KUBECONFIG="$(pwd)/bootkube-assets/auth/kubeconfig"
    kubectl get all --all-namespaces
    ```
1. Add kube-applier to the cluster:
   ```
    kubectl apply -Rf kube-applier/
   ```
1. Share the
   `terraform/clusters/cluster1.gds-re-run-production.aws.ext.govsvc.uk/bootkube-assets/auth/kubeconfig`

1. Commit and Push new `cluster.tf` and the `kube-applier` yaml files file to keep the record.

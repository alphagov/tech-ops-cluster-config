# Government Shared Platform (come up with a better name please) - Teams

...

## Prerequisites

- [Docker Desktop](https://docs.docker.com/install/#supported-platforms) - Container tooling
- [aws-cli](https://github.com/aws/aws-cli) - Universal Command Line Interface for Amazon Web Services
- [aws-vault](https://github.com/99designs/aws-vault) - A vault for securely storing and accessing AWS credentials in development environments
- [aws-iam-authenticator](https://github.com/kubernetes-sigs/aws-iam-authenticator) - A tool to use AWS IAM credentials to authenticate to a Kubernetes cluster
  - `go get -u -v github.com/kubernetes-sigs/aws-iam-authenticator/cmd/aws-iam-authenticator`

## How to register a new cluster

1. Manually `Create S3 Bucket` in the Service Team's AWS account
    * `Bucket name` should resolve to
      `gds-re-${AWS_ACCOUNT_NAME}-terraform-state`
    * `Versioning` should be opt in
    * `Default encryption` should be opt in
1. Manually `Create Hosted Zone` in the Service Team's AWS account
    * `Domain Name` should resolve to
      `${AWS_ACCOUNT_NAME}.aws.ext.govsvc.uk`
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
1. Create cluster Terraform

    Copy an existing cluster configuration from under `terraform/clusters`--you probably want to tweak the `values.auto.tfvars` and `cluster.tf` appropriately.

    This leaves you with a manual steps of:

    ```sh
    cd terraform/clusters/${DOMAIN}

    aws-vault exec run-sandbox -- terraform init -upgrade=true

    aws-vault exec run-sandbox -- terraform apply
    ```

1. Bootstrap cluster

    Clone the [`gsp-terraform-ignition`](https://github.com/alphagov/gsp-terraform-ignition) repo:

    ```sh
    cd bootstraper/

    ./bootstrap.sh run-sandbox
    ```

1. Jump back to `gsp-teams`, generate a `kubeconfig`, apply any generated resources to the cluster, commit the `kubeconfig`:

   ```sh
   aws-vault exec run-sandbox -- terraform output admin-kubeconfig > kubeconfig
   export KUBECONFIG=$(pwd)/kubeconfig
   aws-vault exec run-sandbox -- kubectl apply -Rf addons/
   git add kubeconfig && git commit
   ```

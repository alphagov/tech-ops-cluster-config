# GDS Supported Platform - Teams

Cluster configuration for GDS teams using the GDS Supported Platform.

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
1. Create persistent Terraform

    To create your network and other persistent resources for the base of your cluster, copy an existing configuration to manage from under `terraform/accounts/run-sandbox/persistent`--you probably want to tweak `resources.tf` appropriately.

    This leaves you with a manual steps of:

    ```sh
    export AWS_DEFAULT_REGION=eu-west-2

    cd terraform/accounts/${AWS_ACCOUNT_NAME}/persistent/${DOMAIN}

    aws-vault exec run-sandbox -- terraform init -upgrade=true

    aws-vault exec run-sandbox -- terraform apply
    ```
1. Create cluster Terraform

    Copy an existing cluster configuration from under `terraform/clusters`--you probably want to tweak `cluster.tf` appropriately.

    This leaves you with a manual steps of:

    ```sh
    export AWS_DEFAULT_REGION=eu-west-2

    cd terraform/clusters/${DOMAIN}

    aws-vault exec run-sandbox -- terraform init -upgrade=true

    aws-vault exec run-sandbox -- terraform apply
    ```

1. Generate a `kubeconfig`, apply any generated resources to the cluster, commit the `kubeconfig`:

   ```sh
   aws-vault exec run-sandbox -- terraform output kubeconfig > kubeconfig
   export KUBECONFIG=$(pwd)/kubeconfig
   aws-vault exec run-sandbox -- kubectl apply -Rf addons/ # This will probably need to be run multiple times
   git add cluster.tf kubeconfig && git commit # Create branch as usual best practice
   ```

# Government Shared Platform (come up with a better name please) - Teams

...

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
    | `AWS_ACCOUNT_NAME` | This should match your AWS account name or the account ID. | `gds-re-run-production` |
    | `AWS_REGION` | Should represent AWS region. Stick to London. | `eu-west-2` |
    | `CLUSTER_NAME` | The name of the cluster about to be created. Needs to be unique across your entire Hosted Zone. | `cluster1` |
    | `ZONE_ID` | An AWS Hosted Zone ID which you've obtained from the first step of this guide. | `E00000000000` |
    | `ZONE_NAME` | An AWS Hosted Zone name which you've obtained from the first step of this guide. | `gds-re-run-production.aws.ext.govsvc.uk` |

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

    This leaves you with a manual step of:

    ```sh
    cd terraform/clusters/cluster1.gds-re-run-production.aws.ext.govsvc.uk
    aws-vault exec run-production -- terraform init
    aws-vault exec run-production -- terraform plan
    aws-vault exec run-production -- terraform apply
    ```
1. Test the connection to Kubernetes by executing the following:
    ```
    export KUBECONFIG="$(pwd)/secrets/auth/kubeconfig"
    kubectl get all --all-namespaces
    ```
1. Share the
   `terraform/clusters/cluster1.gds-re-run-production.aws.ext.govsvc.uk/secrets/auth/kubeconfig`
   ```
   aws ssm put-parameter --name "/${domain}/kubeconfig" \
     --type SecureString \
     --value "$(cat secrets/auth/kubeconfig)"
   ```

   In order to read this out of AWS SSM later, run:

   ```
    aws ssm get-parameter --name "/${domain}/kubeconfig" \
      --query Parameter.Value \
      --output text \
      --with-decryption > "~/.kube/${domain}/kubeconfig"
   ```
1. Commit and Push new `cluster.tf` file to keep the record.

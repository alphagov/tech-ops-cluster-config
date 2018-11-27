#!/usr/bin/env bash
set -euo pipefail

: "${CLUSTER_NAME:?Required variable!}"

: "${AWS_REGION:?Required variable!}"
: "${AWS_ACCOUNT_NAME:?Required variable!}"

: "${ZONE_ID:?Required variable!}"
: "${ZONE_NAME:?Required variable!}"

: "${MAIN_PASSWORD:?Required variable!}"

export CLOUD="aws"
export SYSTEM_DOMAIN="ext.govsvc.uk"

domain="${CLUSTER_NAME}.${AWS_ACCOUNT_NAME}.${CLOUD}.${SYSTEM_DOMAIN}"

delete_ssh_keys() {
  rm -f ${domain}.rsa*
}

dir="terraform/clusters/${domain}"
mkdir -p "${dir}"

trap delete_ssh_keys EXIT
ssh-keygen -t rsa -b 4096 -C "${domain}" -f "${domain}.rsa" -N ''

private_key="$(cat ${domain}.rsa)"
public_key="$(cat ${domain}.rsa.pub)"

# NOTE: We may need to add some "expiration" timestamp.
ssh-add "${domain}.rsa"

aws ssm put-parameter --name "/${domain}/ssh-key" \
  --type SecureString \
  --overwrite \
  --value "${private_key}"

cat terraform/templates/cluster.tf | \
sed "s/(AWS_REGION)/${AWS_REGION}/g" | \
sed "s/(AWS_ACCOUNT_NAME)/${AWS_ACCOUNT_NAME}/g" | \
sed "s/(CLUSTER_NAME)/${CLUSTER_NAME}/g" | \
sed "s/(ZONE_ID)/${ZONE_ID}/g" | \
sed "s/(ZONE_NAME)/${ZONE_NAME}/g" | \
sed "s|(PUBLIC_SSH_KEY)|${public_key}|g" | \
sed "s/(CLOUD)/${CLOUD}/g" | \
sed "s/(SYSTEM_DOMAIN)/${SYSTEM_DOMAIN}/g" \
  > "${dir}/cluster.tf"

cp terraform/templates/variables.tfvars "${dir}/variables.tfvars"

echo "cluster file: Created!"
echo "You can continue by changing directory to:"
echo "${dir}"

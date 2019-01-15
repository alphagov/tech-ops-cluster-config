# Applying pipeline

## Before you start

You need the following dependencies installed on your laptop: [`yq`](https://pypi.org/project/yq/), `jq`.

## How to apply the pipeline

```
fly -t gsp set-pipeline -p $ACCOUNT_NAME \
	--config tools-staging-prod-infra.yaml \
	--var account-name=$ACCOUNT_NAME \
	--var account-role-arn=$DEPLOYER_ROLE_ARN \
	--yaml-var public-gpg-keys="$(yq . ../users/*.yaml | jq -s '[.[] | select(.teams[] | IN("re-gsp")) | .pub]')" \
	--check-creds
```

For run-sandbox:
```
fly -t gsp set-pipeline -p run-sandbox-<cluster-name> \
	--config run-sandbox.yaml \
	--var account-name=run-sandbox \
	--var account-role-arn=arn:aws:iam::011571571136:role/deployer \
	--var cluster-name=<cluster-name> \
	--yaml-var public-gpg-keys="$(yq . ../users/*.yaml | jq -s '[.[] | select(.teams[] | IN("re-gsp")) | .pub]')" \
	--check-creds
```

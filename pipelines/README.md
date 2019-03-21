### Applying pipeline


```
fly -t gsp set-pipeline -p $ACCOUNT_NAME \
	--config tools-staging-prod-infra.yaml \
	--var account-name=$ACCOUNT_NAME \
	--var account-role-arn=$DEPLOYER_ROLE_ARN \
	--var public-gpg-keys=$(yq . ../../../users/*.yaml | jq -s '[.[] | select(.teams[] == "re-gsp") | .pub]') \
	--check-creds
```

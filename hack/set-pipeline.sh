#!/bin/bash

set -eu

: "${CLUSTER_NAME:?}"

fly -t cd-gsp sync

fly -t cd-gsp set-pipeline -p "${CLUSTER_NAME}-deployer" --config ../gsp-terraform-ignition/pipelines/deployer/deployer.yaml \
	--load-vars-from ./clusters/${CLUSTER_NAME}.yaml \
	--check-creds

fly -t cd-gsp expose-pipeline -p "${CLUSTER_NAME}-deployer"

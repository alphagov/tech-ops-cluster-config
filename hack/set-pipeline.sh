#!/bin/bash

set -eu -o pipefail

PLATFORM_SRC="../gsp-terraform-ignition"

: "${CLUSTER_NAME:?}"
: "${PATH_TO_USERS:?}"

function git-status-say {
  ( \
    cd "${PLATFORM_SRC}" \
    && git fetch --all >/dev/null \
    && git status --ignore-submodules | grep -i "${1}" >/dev/null \
  )
}

if [[ "$(cd ${PLATFORM_SRC} && git rev-parse --abbrev-ref HEAD)" != "master" ]]; then
  echo "aborting: working copy of ${PLATFORM_SRC} is not on master"
  exit 1
fi
if ! git-status-say "working tree clean"; then
  echo "aborting: working copy of ${PLATFORM_SRC} is not clean"
  exit 1
fi
if ! git-status-say "your branch is up to date"; then
  echo "aborting: working copy of ${PLATFORM_SRC} is not up to date with the remote repository"
  exit 1
fi

approvers="/tmp/deployer-${CLUSTER_NAME}-approvers.yaml"
echo -n "github-approvers: " > "${approvers}"
cat ${PATH_TO_USERS}/*.yaml \
  | yq . \
  | jq -c -s "[.[] | select(.roles[] | select((. == \"${CLUSTER_NAME}-sre\" ) or (. == \"${CLUSTER_NAME}-admin\"))) | .github] | unique" \
  >> "${approvers}"

trusted="/tmp/deployer-${CLUSTER_NAME}-keys.yaml"
echo -n "trusted-developer-keys: " > "${trusted}"
cat ${PATH_TO_USERS}/*.yaml \
  | yq . \
  | jq -c -s '[ .[].pub ]' \
  >> "${trusted}"

fly -t cd-gsp sync

fly -t cd-gsp set-pipeline -p "${CLUSTER_NAME}-deployer" \
  --config "${PLATFORM_SRC}/pipelines/deployer/deployer.yaml" \
	--load-vars-from "./clusters/${CLUSTER_NAME}.yaml" \
  --load-vars-from "${approvers}" \
  --load-vars-from "${trusted}" \
	--check-creds

fly -t cd-gsp expose-pipeline -p "${CLUSTER_NAME}-deployer"

#!/bin/bash

set -eu

PLATFORM_SRC="../gsp-terraform-ignition"

: "${CLUSTER_NAME:?}"

function git-status-not-say {
  ( \
    cd "${PLATFORM_SRC}" \
    && git fetch --all \
    && git status --ignore-submodules | grep -i -v "${1}" \
  )
}

if [[ "$(cd ${PLATFORM_SRC} && git rev-parse --abbrev-ref HEAD)" != "master" ]]; then
  echo "aborting: working copy of ${PLATFORM_SRC} is not on master"
  exit 1
fi
if git-status-not-say "working tree clean"; then
  echo "aborting: working copy of ${PLATFORM_SRC} is not clean"
  exit 1
fi
if git-status-not-say "your branch is up to date"; then
  echo "aborting: working copy of ${PLATFORM_SRC} is not up to date with the remote repository"
  exit 1
fi

fly -t cd-gsp sync

fly -t cd-gsp set-pipeline -p "${CLUSTER_NAME}-deployer" --config "${PLATFORM_SRC}/pipelines/deployer/deployer.yaml" \
	--load-vars-from ./clusters/${CLUSTER_NAME}.yaml \
	--check-creds

fly -t cd-gsp expose-pipeline -p "${CLUSTER_NAME}-deployer"

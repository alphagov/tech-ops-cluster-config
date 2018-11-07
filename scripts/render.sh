#!/usr/bin/env bash

set -euo pipefail

repo_url="${1}"

rm -rf /tmp/gsp-base
mkdir -p /tmp/gsp-base

helm template \
  --output-dir /tmp/gsp-base \
  --name gsp-base \
  --namespace gsp-base \
  --values values.yaml \
  ../../../charts/gsp-base/charts/base

cd /tmp/gsp-base
git init .
git config --local credential.helper '!aws codecommit credential-helper $@'
git config --local credential.UseHttpPath true
git remote add origin "${repo_url}"
git add .
git commit -m "Initial commit by cluster initialisation"
git push -f origin master

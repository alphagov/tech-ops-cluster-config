#!/usr/bin/env bash

set -eu
set -o pipefail

: "${CODECOMMIT_REPO_URL:?Required variable!}"
: "${SOURCE_REPO_URL:?Required variable!}"

temp_dir="$(mktemp -d)"
pushd "$temp_dir"
cleanup() {
  popd
  rm -rf "$temp_dir"
}
trap cleanup EXIT

git init
git config --local credential.helper '!aws codecommit credential-helper $@'
git config --local credential.UseHttpPath true
git remote add source "${SOURCE_REPO_URL}"
git remote add destination "${CODECOMMIT_REPO_URL}"
git fetch --all
dest_master="$(git ls-remote destination master)"

if ! [ -z "$dest_master" ]
then
  echo "Destination repository $CODECOMMIT_REPO_URL already has master branch, nothing to do"
  exit 0
fi

git checkout -b master --track source/master
git push --force destination master


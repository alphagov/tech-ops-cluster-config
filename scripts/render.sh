#!/usr/bin/env bash

mkdir -p ./output

helm template \
  --output-dir ./output \
  --name gsp-base \
  --values values.yaml \
  ../../../charts/gsp-base/charts/base

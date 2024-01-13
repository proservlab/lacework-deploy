#!/bin/bash

apt-get update && apt-get install jq
aws eks update-kubeconfig --name="$(aws eks list-clusters | jq -r '.clusters[0]')"

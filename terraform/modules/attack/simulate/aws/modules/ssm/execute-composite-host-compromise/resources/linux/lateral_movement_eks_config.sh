#!/bin/bash

aws eks update-kubeconfig --name="$(aws eks list-clusters | jq -r '.clusters[0]')"

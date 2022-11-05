#!/bin/bash

kubectl get pods -A -o json | jq -r '.' | jq -r '.items[] | { name: .metadata.name, namespace: .metadata.namespace, containerID: .status.containerStatuses[].containerID }'
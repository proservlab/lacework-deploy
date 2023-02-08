#!/bin/bash

docker run --name=deploy-gcp -w /workspace/terraform -v scenarios:/workspace/terraform/scenarios -it -v $HOME/.lacework.toml:/root/.lacework.toml deploy-gcp:latest
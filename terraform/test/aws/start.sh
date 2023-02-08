#!/bin/bash

docker run --name=deploy-aws -w /workspace/terraform -it -v scenarios:/workspace/terraform/scenarios -v $HOME/.aws:/root/.aws -v $HOME/.lacework.toml:/root/.lacework.toml deploy-aws:latest
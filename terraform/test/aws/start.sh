#!/bin/bash

docker run --name=deploy-aws -w /workspace/terraform --rm -it -v $HOME/.aws:/root/.aws -v $HOME/.lacework.toml:/root/.lacework.toml deploy-aws:latest
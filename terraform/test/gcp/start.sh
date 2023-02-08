#!/bin/bash

docker run --name=deploy-gcp -w /workspace --rm -it -v $HOME/.lacework.toml:/root/.lacework.toml -v $HOME/Documents/dev/lacework-deploy:/workspace deploy-gcp:latest
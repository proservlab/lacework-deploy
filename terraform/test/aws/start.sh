#!/bin/bash

docker run --name=deploy-aws -w /workspace --rm -it -v $HOME/.aws:/root/.aws -v $HOME/.lacework.toml:/root/.lacework.toml -v $HOME/Documents/dev/lacework-deploy:/workspace deploy-aws:latest
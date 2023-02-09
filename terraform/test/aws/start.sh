#!/bin/bash

docker stop deploy-aws
docker rm deploy-aws

docker run -d --name=deploy-aws -w /workspace/terraform -it -v -v "${PWD}/env_vars":/workspace/terraform/env_vars "${PWD}/scenarios":/workspace/terraform/scenarios -v $HOME/.aws:/root/.aws -v $HOME/.lacework.toml:/root/.lacework.toml deploy-aws:latest \
&& docker exec -it deploy-aws /bin/bash
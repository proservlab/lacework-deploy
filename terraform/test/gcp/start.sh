#!/bin/bash

docker stop deploy-gcp
docker rm deploy-gcp

docker run -d --name=deploy-gcp -w /workspace/terraform -v "${PWD}/scenarios":/workspace/terraform/scenarios -it -v $HOME/.lacework.toml:/root/.lacework.toml deploy-gcp:latest \
&& docker exec -it deploy-gcp /bin/bash
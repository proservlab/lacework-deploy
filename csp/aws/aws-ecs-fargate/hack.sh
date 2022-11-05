#!/bin/bash
docker build -t web-image .
docker run -d -p 80:5000 web-image

aws ecr create-repository --repository-name ecs-flask/home
aws ecr get-login --region us-east-1 --no-include-email
docker tag web-image:latest ${ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/ecs-flask/web-image:latest
docker push 526262051452.dkr.ecr.us-east-1.amazonaws.com/ecs-flask/home
#!/bin/bash
# 
# Builds a Docker image and pushes to an AWS ECR repository
#
# Invoked by the terraform-aws-ecr-docker-image Terraform module.
#
# Usage:
#
# # Acquire an AWS session token
# $ ./push.sh . my-profile 123456789012.dkr.ecr.us-west-1.amazonaws.com/hello-world latest
#

set -e

source_path="$1"
image_url="$2"
repository_url="$(echo "$2" | cut -d/ -f1 -f2)"
image_name="$(echo "$2" | cut -d/ -f3)"
repo_password="$(echo "$3" | cut -d' ' -f2)"

(cd "$source_path" && docker build -t "$image_name" .)

echo "$ecr_password" | docker login --username AWS --password-stdin "$repository_url"
docker tag "$image_name" "$image_url"
docker push "$image_url"
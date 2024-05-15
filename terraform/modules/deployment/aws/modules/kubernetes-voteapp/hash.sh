#!/bin/bash
# 
# Calculates hash of Docker image source contents
#
# Invoked by the terraform-aws-ecr-docker-image Terraform module.
#
# Usage:
#
# $ ./hash.sh .
#

set -e

source_path=${1:-.}

MD5_COMMAND=$( if ! command -v md5sum >/dev/null; then echo "md5 -r"; else echo "md5sum"; fi )

# Hash all source files of the Docker image
# Exclude Python cache files, dot files
file_hashes="$(
    cd "$source_path" \
    && find . -type f -not -name '*.pyc' -not -path './.**' \
    | sort \
    | xargs $MD5_COMMAND
)"

hash="$(echo "$file_hashes" | $MD5_COMMAND | cut -d' ' -f1)"

echo '{ "hash": "'"$hash"'" }'
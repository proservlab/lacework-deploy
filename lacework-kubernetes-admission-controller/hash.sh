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

# get the base path for this script
BASEPATH=$(dirname "$0")            # relative
BASEPATH=$(cd "$BASEPATH" && pwd)    # absolutized and normalized
if [[ -z "$BASEPATH" ]] ; then
  exit 1
fi

source_path=${1:-.}

# Hash all source files of the Docker image
# Exclude Python cache files, dot files
file_hashes="$(
    cd "${BASEPATH}/$source_path" \
    && find . -type f -not -name '*.pyc' -not -path './.**' \
    | sort \
    | xargs md5sum
)"

hash="$(echo "$file_hashes" | md5sum  | cut -d' ' -f1)"

echo '{ "hash": "'"$hash"'" }'
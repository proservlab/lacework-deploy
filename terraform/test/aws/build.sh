#!/bin/bash 

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
docker build -t deploy-aws:latest -f ${SCRIPT_DIR}/Dockerfile .
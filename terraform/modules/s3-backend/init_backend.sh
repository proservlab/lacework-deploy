#!/bin/bash

terraform workspace new s3-backend 2> /dev/null
terraform workspace select s3-backend
# no s3 backend as we need to set it up first
terraform init

# setup the backend using the profile and region here
terraform apply -var-file=env_vars/backend.conf

# output include the bucket name for the backend

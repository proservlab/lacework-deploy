#!/bin/bash

STAGE="all"

INFRASTRUCTURE="infrastructure"
SURFACE="attacksurface"
SIMULATION="attacksimulation"

STAGE=${INFRASTRUCTURE}
terraform plan -target=module.target-${STAGE} -target=module.attacker-${STAGE} -out build.tfplan
terraform apply
STAGE=${SURFACE}
terraform plan -target=module.target-${STAGE} -target=module.attacker-${STAGE} -out build.tfplan
terraform apply
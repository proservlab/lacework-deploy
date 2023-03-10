#!/bin/sh

/bin/terraform init
/bin/terraform apply -auto-approve
sleep 600
/bin/terraform destroy -auto-approve
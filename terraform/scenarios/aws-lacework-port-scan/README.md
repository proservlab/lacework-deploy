# aws-lacework-port-scan

## Description

This scenario deploys two target ec2 instance with the lacework agent installed and a single attacker instance. During the attack simulation the attacker will execute nmap port scan against the public facing ec2 target instance. The scenario will also use one of the target instances to attempt an nmap scan of hosts in it's network segment. This can be used to test the detection of nmap binary and port scanning activity internally. Additionally this scenario will test the integration of cloud audit, config and agentless.
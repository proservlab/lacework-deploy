# aws-lacework-low-latency-bad-url

## Description

This scenario deploys a single ec2 instance with the lacework agent that will execute curl every 24 hours to `<RANDOM>.burpsuitecollaborator.net`.This scenario can be used to test low-latecy alerting. Additionally this scenario will test the integration of cloud audit, config and agentless.
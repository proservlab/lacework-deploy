# aws-lacework-composite-ciem-eks

## Description

This scenario covers the compromise of an enternally facing host, leading to unauthorized access to a kubernetes cluster and subsequent data exfiltration from a production s3 bucket.

At a high-level:

* A web server with improper session token security is exposed to the internet
* Attackers brute force the session key and forge a token that provides admin access to the web service
* The admin session allows attackers to gain access to usernames and passwords stored in environment variables
* The password discovered for admin is used to gain access to an internet exposed jump server via ssh
* From the compromised host attackers enumerate the local system and complete a network scan. 
* The local scan reveals an ssh private key and the network scan reveals an internal kubernetes management server
* Attacker use the private key to gain user-level access to the kubernetes management server
* Attackers then escalate privilege to root using docker
* As the root user the attackers discover kubernetes `~/.kube/config` and `~/.aws/credentials`
* The kubernetes config and credentials are exfiltrated to the attackers server
* Attackers, from their host, use the tor network to enumerate both kubernetes and the aws cloud environment
* During the enumeration of the kubenetes cluster attacker discover the `s3app` pod which is using OIDC to assume a role `eks-s3-dev-role`
* Attackers leverage the limited permissions they have to the kubernetes cluster to start a cronjob where they establish a reverse shell in a pod using the `eks-s3-dev-role`
* Inside the compromised pod attackers once again enumerate their access to discover they have access to two s3 buckets `eks-data-dev` and `eks-data-prod` due to a misconfigured role policy `arn:aws:s3:::eks-data-*`
* From inside the compromised pod attacker exfiltrate `production.db`

## Diagram

```mermaid
graph TD
  %% Root Node
  subgraph aws["AWS"]
    
    %% AWS Accounts
    subgraph attacker["Attacker"]
      Public_Instances_attacker["Public VPC"]
      
      %% Attacker Public Instances
      subgraph Public_Instances_attacker["Public VPC"]
        subgraph public-attacker-1["public-attacker-1"]
          pwncat_public-attacker-1(reverse shell handler<br/>Port: 4444)
          exploit.bin_public-attacker-1(session token exploit<br/>Port: None)
        end
      end
    end
    
    subgraph target["Target"]
      Public_Instances_target["Public VPC"]
      Private_Instances_target["Private VPC"]
      EKS_Instances_target["EKS Clusters"]
      S3_Instances_target["S3 Buckets"]

      %% Target Public Instances
      subgraph Public_Instances_target["Public VPC"]
        subgraph public-target-1["jumpserver"]
            nginx_public-target-1(ssh<br/>Port: 22)
            reverse_shell-target-1(/bin/bash<br/>Port: None)
        end
      end
      subgraph Private_Instances_target["Private VPC"]
        subgraph private-target-1["private-target-1"]
            ssh_private-target-1(/bin/bash<br/>Port: None)
        end
      end
      subgraph EKS_Instances_target["EKS Clusters"]
        subgraph dev-target-1["dev-target-1"]
            authapp(Pod: authapp<br/>Port: 8080<br/>Role: default)
            s3app(Pod: s3app<br/>Port:8080<br/>Role: s3-access-role)
            reverseshell_pod(Pod: reverse-shell-cron<br/>Port:None<br/>Role: s3-access-role)
        end
      end
      subgraph S3_Instances_target["S3 Buckets"]
        subgraph dev-bucket-1["eks-data-dev"]
            
        end
        subgraph prod-bucket-1["eks-data-prod"]
            
        end
      end
    end

  end

  %% Example Attack Flow
  exploit.bin_public-attacker-1 -->|"1. Exploit insecure session token"| authapp
  pwncat_public-attacker-1 -->|"2. Unauthorized SSH Access"| nginx_public-target-1


  %% Local Enumeration and Credential Discovery
  reverse_shell-target-1 -->|"2. Local Enumeration"| local_enum["/bin/bash linpeas.sh"]
  local_enum -->|"3. Network Enumeration"| network_discovery["nmap"]
  network_discovery -->|"4. Private Key Discovery"| private_key["~/.ssh/private_key"]
  private_key -->|"5. Lateral Movement"| ssh_private-target-1

  ssh_private-target-1 -->|"6. Local Enumeration"| local_enum_2["/bin/bash linpeas.sh"]
  local_enum_2 -->|"7. Privilege Escalation to Root"| privilege_escalate["docker run"]
  privilege_escalate -->|"8. Exfiltrate Kubernetes Creds"| exfil_kube["~/.kube/config"]
  exfil_kube -->|"8. Exfiltrate AWS Creds"| exfil_aws["~/.aws/credentials"]

 %% Kubernetes enumerate

 pwncat_public-attacker-1 -->|"9. Kubernetes Enumeration"| dev-target-1
 pwncat_public-attacker-1 -->|"10. OIDC Credentials Discovery"| s3app

 s3app -->dev-bucket-1 

 pwncat_public-attacker-1 -->|"11. Start Reverse Shell Cron"| reverseshell_pod
 reverseshell_pod -->|"11. Exfiltrate S3 Data"| prod-bucket-1


  %% Styling Classes
  classDef rounded-corner stroke:#333,stroke-width:2px,rx:10,ry:10;
  
  %% Apply Rounded Corner Class
  class aws,attacker,private-target-1,ssh_private-target-1,Private_Instances_target,dev-target-1,EKS_Instances_target,exfil_kube,exfil_aws,privilege_escalate,local_enum_2,private_key,network_discovery,db-bucket-1,dev-db-1,RDS_Instances_target,S3_Instances_target,Public_Instances_attacker,public-attacker-1,pwncat_public-attacker-1,exploit.bin_public-attacker-1,target,Public_Instances_target,public-target-1,public-target-2,nginx_public-target-1,ssh_public-target-1,local_enum,cred_discovery,scout_enum,exfiltration rounded-corner;
```

## Walkthrough

Alright, we’re going to walk you through a demo and storyline that we documented as part of actual **attack scenarios** we’ve observed in **our customers' environments**. The demo itself outlines a compromise scenario demonstrating why CSPM itself isn’t enough and that you need both threat and risk context from your CNAPP to effectively secure your cloud environment. 

You’ll see some of the innovations released in the last year including:

* **composite alerts**
* **CIEM**
* **alert context panels**
* **attack path analysis** and **security graph**
* **kubernetes audit logs monitoring**

We’ve got a lot to cover, let’s get started.

In our scenario, we have a fictitious company, Interlace Labs. Interlace Labs recently brought onboard a new developer who, as part of his onboarding tasks was asked to clone a template application and deploy to the development EKS cluster. He was also provided with the DNS name for the _legacy_ jumpserver the provides access to and internal kubernetes management server for the development the EKS cluster.

However, a few hours later, the security team at Interlace Labs receives multiple high and critical event notifications from Lacework, indicating suspicious activity within their cloud account. We can see these here in the Alerts Dashboard.
graph TD
  %% Root Node
  subgraph aws["AWS"]
    
    %% AWS Accounts
    subgraph attacker["Attacker"]
      Public_Instances_attacker["Public VPC"]
      
      %% Attacker Public Instances
      subgraph Public_Instances_attacker["Public VPC"]
        subgraph public-attacker-1["public-attacker-1"]
          pwncat_public-attacker-1(reverse shell handler<br/>Port: 4444,1389,8080)
          exploit.bin_public-attacker-1(log4j exploit<br/>Port: None)
        end
      end
    end
    
    subgraph target["Target"]
      Public_Instances_target["Public VPC"]
    %%   Private_Instances_target["Private VPC"]
    %%   EKS_Instances_target["EKS Clusters"]
      S3_Instances_target["S3 Buckets"]

      %% Target Public Instances
      subgraph Public_Instances_target["Public VPC"]
        subgraph public-target-1["developer"]
            nginx_public-target-1(log4j app<br/>Port: 80)
            reverse_shell-target-1(/bin/bash<br/>Port: None)
        end
      end
    %%   subgraph Private_Instances_target["Private VPC"]
    %%     subgraph private-target-1["private-target-1"]
    %%         nginx_private-target-2(log4j app<br/>Port: 80)
    %%         ssh_private-target-2(/bin/bash<br/>Port: None)
    %%     end
    %%   end
    %%   subgraph EKS_Instances_target["EKS Clusters"]
    %%     subgraph dev-target-1["dev-target-1"]
    %%         authapp(Pod: authapp<br/>Port: 8080<br/>Role: default)
    %%         s3app(Pod: s3app<br/>Port:8080<br/>Role: s3-access-role)
    %%     end
    %%   end
      subgraph S3_Instances_target["S3 Buckets"]
        %% subgraph dev-bucket-1["dev-bucket-1"]
            
        %% end
        %% subgraph prod-bucket-1["prod-bucket-1"]
            
        %% end
        subgraph db-bucket-1["db-bucket-1"]
            
        end
      end
      subgraph RDS_Instances_target["RDS Instaces"]
        subgraph dev-db-1["dev-db-1"]
            
        end
      end
    end

  end

  %% Example Attack Flow
  exploit.bin_public-attacker-1 -->|"1. Exploit log4j"| nginx_public-target-1
  nginx_public-target-1 -->|"2. Establish C2 TASK=iam2rds"| pwncat_public-attacker-1
  pwncat_public-attacker-1 -->|"3. Reverse Shell "| reverse_shell-target-1

  %% Local Enumeration and Credential Discovery
  reverse_shell-target-1 -->|"4. Local Enumeration"| local_enum["/bin/bash linpeas.sh"]
  local_enum -->|"5. Credential Exfiltration"| cred_discovery["AWS Credential Discovery"]

  %% Cloud Enumeration with ScoutSuite
  cred_discovery -->|"6. Cloud Enumeration with ScoutSuite"| scout_enum["Cloud Enumeration with ScoutSuite"]

  %% Example Attack Steps
  scout_enum -->|"7. Data Exfiltration"| exfiltration["RDS Exfiltration via StartExportTask"]
  
  %% RDS Access
  exfiltration -->|"8. StartExportTask Backup to S3"| dev-db-1
  
  %% S3 Backup
  dev-db-1 -->|"9. DB Backup"| db-bucket-1
  
  %% S3 Exfil
  db-bucket-1 -->|"10. Exfil Backup"| pwncat_public-attacker-1

  %% Example Attack Steps
%%   dev-target-1 -->|"iam role access"| dev-bucket-1

  %% Styling Classes
  classDef rounded-corner stroke:#333,stroke-width:2px,rx:10,ry:10;
  
  %% Apply Rounded Corner Class
  class aws,attacker,db-bucket-1,dev-db-1,RDS_Instances_target,S3_Instances_target,Public_Instances_attacker,public-attacker-1,pwncat_public-attacker-1,exploit.bin_public-attacker-1,target,Public_Instances_target,public-target-1,public-target-2,nginx_public-target-1,ssh_public-target-1,local_enum,cred_discovery,scout_enum,exfiltration rounded-corner;
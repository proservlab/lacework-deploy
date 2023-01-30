locals {
  a_records = join(",", [ for record in var.records: 
                "${record.recordName}:${record.recordValue}" 
                if record.recordType == "a" 
              ])
  cname_records = join(",", [ for record in var.records: 
                    "${record.recordName}:${record.recordValue}"
                    if record.recordType == "cname"
                  ])
}

resource "null_resource" "cname_dns_record" {
  triggers = {
    dynu_api_token  = var.dynu_api_token 
    dynu_dns_domain = var.dynu_dns_domain
    cname_records = local.cname_records
  }
  provisioner "local-exec" {
    command =   <<-EOT
                set -e
                DYNU_DOMAIN_ID=$(curl -sLJ https://api.dynu.com/v2/dns -H "accept: application/json" -H "API-Key: ${ self.triggers.dynu_api_token }" | jq -r '.domains[] | select( .name=="${ self.triggers.dynu_dns_domain }" ) | .id ')
                for record in $(echo "${self.triggers.cname_records}"|tr "," "\n"); do 
                RESULT=$(curl -sLJ -X POST https://api.dynu.com/v2/dns/$DYNU_DOMAIN_ID/record -H "accept: application/json" -H "API-Key: ${ self.triggers.dynu_api_token }" -H "Content-Type: application/json" -d "{\"nodeName\":\"$( echo $record | cut -d ":" -f 1 )\",\"recordType\":\"CNAME\",\"ttl\":90,\"state\":true,\"host\":\"$( echo $record | cut -d ":" -f 2 )\"}")
                echo "Created Record: $RESULT"
                done
                EOT
  }
  


  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
                set -e
                DYNU_DOMAIN_ID=$(curl -sLJ https://api.dynu.com/v2/dns -H "accept: application/json" -H "API-Key: ${ self.triggers.dynu_api_token }" | jq -r '.domains[] | select( .name=="${ self.triggers.dynu_dns_domain }" ) | .id ')
                for record in $(echo "${self.triggers.cname_records}"|tr "," "\n"); do 
                DYNU_RECORD_ID=$(curl -sLJ https://api.dynu.com/v2/dns/$DYNU_DOMAIN_ID/record -H "accept: application/json" -H "API-Key: ${ self.triggers.dynu_api_token }" | jq -r '.dnsRecords[] | select( .hostname=="$( echo $record | cut -d ":" -f 1 ).${ self.triggers.dynu_dns_domain }" ) | select( .recordType=="CNAME" ) | select( .state==true ) | .id')
                echo "Deleting Record $DYNU_RECORD_ID from Domain $DYNU_DOMAIN_ID."
                RESULT=$(curl -sLJ -X DELETE https://api.dynu.com/v2/dns/$DYNU_DOMAIN_ID/record/$DYNU_RECORD_ID -H "accept: application/json" -H "API-Key: ${ self.triggers.dynu_api_token }")
                echo "Deleted Record: $RESULT"
                done
                EOT
  }
}

resource "time_sleep" "wait_60_seconds_1" {
  depends_on = [null_resource.cname_dns_record]

  create_duration = "60s"
}

resource "null_resource" "a_dns_record" {
  triggers = {
    dynu_api_token  = var.dynu_api_token 
    dynu_dns_domain = var.dynu_dns_domain
    a_records = local.a_records
  }
  provisioner "local-exec" {
    command =   <<-EOT
                set -e
                DYNU_DOMAIN_ID=$(curl -sLJ https://api.dynu.com/v2/dns -H "accept: application/json" -H "API-Key: ${ self.triggers.dynu_api_token }" | jq -r '.domains[] | select( .name=="${ self.triggers.dynu_dns_domain }" ) | .id ')
                for record in $(echo "${self.triggers.a_records}"|tr "," "\n"); do 
                RESULT=$(curl -sLJ -X POST https://api.dynu.com/v2/dns/$DYNU_DOMAIN_ID/record -H "accept: application/json" -H "API-Key: ${ self.triggers.dynu_api_token }" -H "Content-Type: application/json" -d "{\"nodeName\":\"$( echo $record | cut -d ":" -f 1 )\",\"recordType\":\"A\",\"ttl\":90,\"state\":true,\"group\": \"\",\"ipv4Address\":\"$( echo $record | cut -d ":" -f 2 )\"}")
                echo "Created Record: $RESULT"
                done
                EOT
  }
  
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
                set -e
                DYNU_DOMAIN_ID=$(curl -sLJ https://api.dynu.com/v2/dns -H "accept: application/json" -H "API-Key: ${ self.triggers.dynu_api_token }" | jq -r '.domains[] | select( .name=="${ self.triggers.dynu_dns_domain }" ) | .id ')
                for record in $(echo "${self.triggers.a_records}"|tr "," "\n"); do 
                DYNU_RECORD_ID=$(curl -sLJ https://api.dynu.com/v2/dns/$DYNU_DOMAIN_ID/record -H "accept: application/json" -H "API-Key: ${ self.triggers.dynu_api_token }" | jq -r '.dnsRecords[] | select( .hostname=="$( echo $record | cut -d ":" -f 1 ).${ self.triggers.dynu_dns_domain }" ) | select( .recordType=="A" ) | select( .state==true ) | .id')
                echo "Deleting Record $DYNU_RECORD_ID from Domain $DYNU_DOMAIN_ID."
                RESULT=$(curl -sLJ -X DELETE https://api.dynu.com/v2/dns/$DYNU_DOMAIN_ID/record/$DYNU_RECORD_ID -H "accept: application/json" -H "API-Key: ${ self.triggers.dynu_api_token }")
                echo "Deleted Record: $RESULT"
                done
                EOT
  }

  depends_on = [
    time_sleep.wait_60_seconds_1
  ]
}

resource "time_sleep" "wait_60_seconds_2" {
  depends_on = [null_resource.a_dns_record]

  create_duration = "60s"
}
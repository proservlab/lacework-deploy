resource "null_resource" "cname_dns_record" {
  for_each = { 
    for index, record in [ 
        for record in var.records: record if record.recordType == "cname" 
      ]: record.recordName => record 
  }
  triggers = {
    dynu_api_token  = var.dynu_api_token 
    dynu_api_token     = var.dynu_api_token
  }
  provisioner "local-exec" {
    command =   <<-EOT
                set -e
                DYNU_DOMAIN_ID=$(curl https://api.dynu.com/v2/dns -H "accept: application/json" -H "API-Key: ${ self.triggers.dynu_api_token }" -sLJ | jq -r '.domains[] | select( .name=="${ self.triggers.dynu_dns_domain }" ) | .id ')
                curl -X POST https://api.dynu.com/v2/dns/$DYNU_DOMAIN_ID/record -H "accept: application/json" -H "API-Key: ${ self.triggers.dynu_api_token }" \
-H "Content-Type: application/json" -d "{\"nodeName\":\"${ each.key }\",\"recordType\":\"CNAME\",\"ttl\":90,\"state\":true,\"host\":\"${ each.value.recordValue }\"}"
                EOT
  }
  


  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
                set -e
                DYNU_DOMAIN_ID=$(curl https://api.dynu.com/v2/dns -H "accept: application/json" -H "API-Key: ${ self.triggers.dynu_api_token }" -sLJ | jq -r '.domains[] | select( .name=="${ self.triggers.dynu_dns_domain }" ) | .id ')
                DYNU_RECORD_ID=$(curl https://api.dynu.com/v2/dns/$DYNU_DNS_ID/record -H "accept: application/json" -H "API-Key: ${ self.triggers.dynu_api_token }" -sLJ | jq -r '.dnsRecords[] | select( .hostname=="${ each.key }.${ self.triggers.dynu_dns_domain }" ) | select( .recordType=="CNAME" ) | select( .state==true ) | .id')
                curl -X DELETE https://api.dynu.com/v2/dns/$DYNU_DOMAIN_ID/record/$DYNU_RECORD_ID -H "accept: application/json" -H "API-Key: ${ self.triggers.dynu_api_token }"
                EOT
  }
}

resource "null_resource" "a_dns_record" {
  for_each = { 
    for index, record in [ 
        for record in var.records: record if record.recordType == "a" 
      ]: record.recordName => record 
  }
  triggers = {
    dynu_api_token  = var.dynu_api_token 
    dynu_api_token     = var.dynu_api_token
  }
  provisioner "local-exec" {
    command =   <<-EOT
                set -e
                DYNU_DOMAIN_ID=$(curl https://api.dynu.com/v2/dns -H "accept: application/json" -H "API-Key: ${ self.triggers.dynu_api_token }" -sLJ | jq -r '.domains[] | select( .name=="${ self.triggers.dynu_dns_domain }" ) | .id ')
                curl -X POST https://api.dynu.com/v2/dns/$DYNU_DOMAIN_ID/record -H "accept: application/json" -H "API-Key: ${ self.triggers.dynu_api_token }" \
-H "Content-Type: application/json" -d "{\"nodeName\":\"${ each.key }\",\"recordType\":\"A\",\"ttl\":90,\"state\":true,\"group\": \"\",\"ipv4Address\":\"${ each.value.recordValue }\"}"
                EOT
  }
  
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
                set -e
                DYNU_DOMAIN_ID=$(curl https://api.dynu.com/v2/dns -H "accept: application/json" -H "API-Key: ${ self.triggers.dynu_api_token }" -sLJ | jq -r '.domains[] | select( .name=="${ self.triggers.dynu_dns_domain }" ) | .id ')
                DYNU_RECORD_ID=$(curl https://api.dynu.com/v2/dns/$DYNU_DNS_ID/record -H "accept: application/json" -H "API-Key: ${ self.triggers.dynu_api_token }" -sLJ | jq -r '.dnsRecords[] | select( .hostname=="${ each.key }.${ self.triggers.dynu_dns_domain }" ) | select( .recordType=="A" ) | select( .state==true ) | .id')
                curl -X DELETE https://api.dynu.com/v2/dns/$DYNU_DOMAIN_ID/record/$DYNU_RECORD_ID -H "accept: application/json" -H "API-Key: ${ self.triggers.dynu_api_token }"
                EOT
  }
}
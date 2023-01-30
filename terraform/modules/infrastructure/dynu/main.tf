resource "null_resource" "cname_dns_record" {
  for_each = { 
    for index, record in [ 
        for record in var.records: record if record.recordType == "cname" 
      ]: record.recordName => record 
  }
  triggers = {
    dynu_api_token  = var.dynu_api_token 
    dynu_dns_domain = var.dynu_dns_domain
  }
  provisioner "local-exec" {
    command =   <<-EOT
                set -e
                DYNU_DOMAIN_ID=$(curl -sLJ https://api.dynu.com/v2/dns -H "accept: application/json" -H "API-Key: ${ self.triggers.dynu_api_token }" | jq -r '.domains[] | select( .name=="${ self.triggers.dynu_dns_domain }" ) | .id ')
                RESULT=$(curl -sLJ -X POST https://api.dynu.com/v2/dns/$DYNU_DOMAIN_ID/record -H "accept: application/json" -H "API-Key: ${ self.triggers.dynu_api_token }" -H "Content-Type: application/json" -d "{\"nodeName\":\"${ each.key }\",\"recordType\":\"CNAME\",\"ttl\":90,\"state\":true,\"host\":\"${ each.value.recordValue }\"}")
                echo "Created Record: $RESULT"
                EOT
  }
  


  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
                set -e
                DYNU_DOMAIN_ID=$(curl -sLJ https://api.dynu.com/v2/dns -H "accept: application/json" -H "API-Key: ${ self.triggers.dynu_api_token }" | jq -r '.domains[] | select( .name=="${ self.triggers.dynu_dns_domain }" ) | .id ')
                sleep 60
                DYNU_RECORD_ID=$(curl -sLJ https://api.dynu.com/v2/dns/$DYNU_DOMAIN_ID/record -H "accept: application/json" -H "API-Key: ${ self.triggers.dynu_api_token }" | jq -r '.dnsRecords[] | select( .hostname=="${ each.key }.${ self.triggers.dynu_dns_domain }" ) | select( .recordType=="CNAME" ) | select( .state==true ) | .id')
                echo "Deleting Record $DYNU_RECORD_ID from Domain $DYNU_DOMAIN_ID."
                curl -sLJ -X DELETE https://api.dynu.com/v2/dns/$DYNU_DOMAIN_ID/record/$DYNU_RECORD_ID -H "accept: application/json" -H "API-Key: ${ self.triggers.dynu_api_token }"
                EOT
  }
}

resource "time_sleep" "wait_60_seconds_1" {
  depends_on = [null_resource.cname_dns_record]

  create_duration = "60s"
}

resource "null_resource" "a_dns_record" {
  for_each = { 
    for index, record in [ 
        for record in var.records: record if record.recordType == "a" 
      ]: record.recordName => record 
  }
  triggers = {
    dynu_api_token  = var.dynu_api_token 
    dynu_dns_domain = var.dynu_dns_domain
  }
  provisioner "local-exec" {
    command =   <<-EOT
                set -e
                DYNU_DOMAIN_ID=$(curl -sLJ https://api.dynu.com/v2/dns -H "accept: application/json" -H "API-Key: ${ self.triggers.dynu_api_token }" | jq -r '.domains[] | select( .name=="${ self.triggers.dynu_dns_domain }" ) | .id ')
                RESULT=$(curl -sLJ -X POST https://api.dynu.com/v2/dns/$DYNU_DOMAIN_ID/record -H "accept: application/json" -H "API-Key: ${ self.triggers.dynu_api_token }" -H "Content-Type: application/json" -d "{\"nodeName\":\"${ each.key }\",\"recordType\":\"A\",\"ttl\":90,\"state\":true,\"group\": \"\",\"ipv4Address\":\"${ each.value.recordValue }\"}")
                echo "Created Record: $RESULT"
                EOT
  }
  
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
                set -e
                DYNU_DOMAIN_ID=$(curl -sLJ https://api.dynu.com/v2/dns -H "accept: application/json" -H "API-Key: ${ self.triggers.dynu_api_token }" | jq -r '.domains[] | select( .name=="${ self.triggers.dynu_dns_domain }" ) | .id ')
                sleep 60
                DYNU_RECORD_ID=$(curl -sLJ https://api.dynu.com/v2/dns/$DYNU_DOMAIN_ID/record -H "accept: application/json" -H "API-Key: ${ self.triggers.dynu_api_token }" | jq -r '.dnsRecords[] | select( .hostname=="${ each.key }.${ self.triggers.dynu_dns_domain }" ) | select( .recordType=="A" ) | select( .state==true ) | .id')
                echo "Deleting Record $DYNU_RECORD_ID from Domain $DYNU_DOMAIN_ID."
                curl -sLJ -X DELETE https://api.dynu.com/v2/dns/$DYNU_DOMAIN_ID/record/$DYNU_RECORD_ID -H "accept: application/json" -H "API-Key: ${ self.triggers.dynu_api_token }"
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
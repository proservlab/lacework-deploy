##################################################
# MODULE ID
##################################################

module "id" {
  source = "../../../context/deployment"
}

data "http" "workstation-external-ip" {
  url = "http://ipv4.icanhazip.com"
}

locals {
  workstation-external-cidr = "${chomp(data.http.workstation-external-ip.response_body)}/32"
  workstation-external = "${chomp(data.http.workstation-external-ip.response_body)}"
}
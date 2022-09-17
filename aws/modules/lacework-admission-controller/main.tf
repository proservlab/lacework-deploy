module "lacework_admission_controller" {
  source  = "lacework/admission-controller/kubernetes"
  version = "~> 0.1"

  lacework_account_name = "${var.lacework_account_name}"
  proxy_scanner_token   = "${var.proxy_token}"
  registries = [
    {
      name      = "myRegistry"
      domain    = "index.docker.io"
      ssl       = true
      auto_poll = false
      poll_frequency_minutes = 20
      disable_non_os_package_scanning = false
    }
  ]
}
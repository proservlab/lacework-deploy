module "lacework_admission_controller" {
  source  = "lacework/admission-controller/kubernetes"
  version = "~> 0.1"

  lacework_account_name = "${var.lacework_account_name}"
  proxy_scanner_token   = "${var.proxy_token}"
  default_registry      = "index.docker.io"
  static_cache_location = "/opt/lacework"
  scan_public_registries = true

  registries = [
    {
      name      = "myRegistry"
      domain    = "index.docker.io"
      ssl       = true
      auto_poll = false
      is_public = true
      poll_frequency_minutes = 20
      disable_non_os_package_scanning = false
      go_binary_scanning = {
        enabled = true
      }
    }
  ]
}
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
      name      = "docker_public"
      domain    = "index.docker.io"
      ssl       = true
      auto_poll = false
      is_public = true
      disable_non_os_package_scanning = false
    },
    {
      name      = "github_public"
      domain    = "ghcr.io"
      ssl       = true
      auto_poll = false
      is_public = true
      disable_non_os_package_scanning = false
      notification_type = "ghcr"
    }
  ]
}
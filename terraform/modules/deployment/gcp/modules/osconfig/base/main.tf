#####################################################
# GCP OSCONFIG
#####################################################

locals {
    resource_name = "${replace(substr(var.tag,0,35), "_", "-")}-${var.environment}-${var.deployment}-${random_string.this.id}"
}

resource "random_string" "this" {
    length            = 4
    special           = false
    upper             = false
    lower             = true
    numeric           = true
}

data "google_compute_zones" "available" {
  project     = var.gcp_project_id
  region    = var.gcp_location
}

resource "google_os_config_os_policy_assignment" "this" {

  project     = var.gcp_project_id
  location    = data.google_compute_zones.available.names[0]
  
  name        = "${local.resource_name}"
  description = "Attack automation"
  skip_await_rollout = true
  
  instance_filter {
    all = false

    inclusion_labels {
      labels = jsondecode(<<-EOT
                            { 
                              "${var.tag}": "true",
                              "deployment": "${var.deployment}",
                              "environment": "${var.environment}"
                            }
                            EOT
                          )
    }

    inventories {
      os_short_name = "ubuntu"
    }

    inventories {
      os_short_name = "debian"
    }

    inventories {
      os_short_name = "centos"
    }

    inventories {
      os_short_name = "rocky"
    }

  }

  os_policies {
    id        = "${local.resource_name}"
    mode = "ENFORCEMENT"

    resource_groups {
      resources {
        id = "run"
        exec {
          validate {
            interpreter      = "SHELL"
            script           = "if echo '${sha256(var.base64_payload)} /tmp/payload_${var.tag}' | tee /tmp/check_${var.tag} | sha256sum --check --status; then exit 100; else exit 101; fi"
          }
          enforce {
            interpreter      = "SHELL"
            script           = "nohup /bin/sh -c \"echo -n '${var.base64_payload}' | tee /tmp/payload_${var.tag} | base64 -d | gunzip | /bin/bash -\" >/dev/null 2>&1 & exit 100"
          }
        }
      }
    }
    allow_no_resource_group_match = false
  }

  rollout {
    disruption_budget {
      percent = 100
    }

    min_wait_duration = "3s"
  }
}
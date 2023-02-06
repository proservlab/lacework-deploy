resource "random_uuid" "agent" {
}

resource "lacework_agent_access_token" "agent" {
    count = can(length(var.lacework_agent_access_token)) ? 0 : 1
    name = "endpoint-gcp-agent-access-token-${var.environment}-${var.deployment}"
}

resource "google_os_config_os_policy_assignment" "install-lacework-agent" {

  project     = var.gcp_project_id
  location    = var.gcp_location
  name        = "lacework-install-policy-${var.environment}-${var.deployment}"
  description = "OS policy to install Lacework agent"

  instance_filter {
    all = false

    inclusion_labels {
      labels = {
        osconfig_deploy_lacework = true
      }
    }
  }

  os_policies {
    id   = "lacework-install-policy"
    mode = "ENFORCEMENT"

    resource_groups {
      resources {
        id = "apt-repo"
        repository {
          apt {
            uri          = "https://packages.lacework.net/latest/DEB/debian"
            archive_type = "DEB"
            distribution = "buster"
            components   = ["main"]
            gpg_key      = "http://keyserver.ubuntu.com/pks/lookup?op=get&search=0x360d55d76727556814078e25ff3e1d4dee0cc692"
          }
        }
      }
      resources {
        id = "apt-install"

        pkg {
          desired_state = "INSTALLED"

          apt {
            name = "lacework"
          }
        }
      }
      resources {
        id = "create-lacework-config"
        exec {
          validate {
            interpreter      = "SHELL"
            output_file_path = "/$HOME/os-policy-tf.out"
            script           = "if test -f /var/lib/lacework/config/config.json; then exit 100; else exit 101; fi"
          }
          enforce {
            interpreter      = "SHELL"
            output_file_path = "$HOME/os-policy-tf.out"
            script           = "echo '{\"Tokens\": {\"Accesstoken\": \"${can(length(var.lacework_agent_access_token)) ? var.lacework_agent_access_token : lacework_agent_access_token.agent[0].token}\"}, \"serverurl\": \"${var.lacework_server_url}\" }' > /var/lib/lacework/config/config.json && exit 100"
          }
        }
      }
    }
  }

  rollout {
    disruption_budget {
      fixed = 1
    }
    min_wait_duration = "3.5s"
  }
}
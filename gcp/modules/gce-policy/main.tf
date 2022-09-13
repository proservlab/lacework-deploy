resource "google_os_config_os_policy_assignment" "primary" {
  instance_filter {
    all = true

    # exclusion_labels {
    #   labels = {
    #     label-two = "value-two"
    #   }
    # }

    # inclusion_labels {
    #   labels = {
    #     label-one = "value-one"
    #   }
    # }

    # inventories {
    #   os_short_name = "centos"
    #   os_version    = "8.*"
    # }
  }

  location = "us-central1"
  name     = "policy-assignment"

  os_policies {
    id   = "policy"
    mode = "VALIDATION"

    resource_groups {
      resources {
        id = "exec1"

        exec {
          validate {
            interpreter      = "SHELL"
            output_file_path = "$HOME/validate"
            script           = "pwd"
          }

          enforce {
            interpreter      = "SHELL"
            output_file_path = "$HOME/enforce"
            script           = "pwd"
          }
        }
      }
    }

    resource_groups {
      resources {
        id = "file1"

        file {
          path    = "$HOME/file"
          state   = "PRESENT"
          content = "${var.environment}-sample-content"
        }
      }
    }
  }

  rollout {
    disruption_budget {
      percent = 1
    }

    min_wait_duration = "3.5s"
  }

  description = "${var.environment} os policy assignment"
  project     = "${var.environment}-project"
}
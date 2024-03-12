resource "lacework_query" "t1552-001" {
    query_id = "TF_CUSTOM_CONTAINER_MOUNT_NODE_FILESYSTEM"
    query    = <<-EOT
    {
        source {
            LW_HA_SYSCALLS_FILE
        }
        filter {
            TARGET_OP in ('create', 'modify') and TARGET_PATH like any('%/.aws/credentials%', '%/.aws/config%', '%/.config/gcloud/%.json%')
        }
        return distinct {
            RECORD_CREATED_TIME,
            MID,
            TARGET_OP,
            TARGET_PATH
        }
    }
    EOT
}

resource "lacework_policy" "t1552-001" {
  title       = "T1552.001: Unsecured Credentials: Credentials In Files"
  description = "Adversaries may search local file systems and remote file shares for files containing insecurely stored credentials. These can be files created by users to store their own credentials, shared credential stores for a group of individuals, configuration files containing passwords for a system or service, or source code/binary files containing embedded passwords."
  remediation = "Remove any hard coded credentials in files."
  query_id    = lacework_query.t1552-001.id
  severity    = "High"
  type        = "Violation"
  evaluation  = "Hourly"
  # tags        = ["domain:AWS", "custom"]
  enabled     = true

  alerting {
    enabled = true
    profile = "LW_HA_SYSCALLS_FILE_DEFAULT_PROFILE.Violation"
  }
}
    
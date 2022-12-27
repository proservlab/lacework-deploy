resource "lacework_query" "t1053-003" {
    query_id = "TF_CUSTOM_SYSCALL_CRON_QUERY"
    query    = <<-EOT
    {
      source {
            LW_HA_SYSCALLS_FILE
      }
      filter {
            TARGET_OP like any('create','modify') AND TARGET_PATH like any('/etc/cron.%','/var/spool/cron/%')
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

resource "lacework_policy" "t1053-003" {
  title       = "T1053.003: Cron"
  description = "Adversaries may abuse the cron utility to perform task scheduling for initial or recurring execution of malicious code."
  remediation = "Review access context and revoke keys as necessary"
  query_id    = lacework_query.t1053-003.id
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
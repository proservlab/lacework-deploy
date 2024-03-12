# resource "lacework_query" "t1098-004" {
#     query_id = "TF_CUSTOM_SYSCALL_SSH_KEYS_QUERY"
#     query    = <<-EOT
#     {
#       source {
#             LW_HA_SYSCALLS_FILE
#       }
#       filter {
#             TARGET_OP like any('create','modify') AND TARGET_PATH like any('%/.ssh/authorized_keys','%/ssh/sshd_config')
#       }
#       return distinct {
#             RECORD_CREATED_TIME,
#             MID,
#             TARGET_OP,
#             TARGET_PATH
#       }
#     }
#     EOT
# }

# resource "lacework_policy" "t1098-004" {
#   title       = "T1098.004: SSH Authorized Keys"
#   description = "Adversaries may modify the SSH authorized_keys file to maintain persistence on a victim host."
#   remediation = "Review access context and revoke keys as necessary"
#   query_id    = lacework_query.t1098-004.id
#   severity    = "High"
#   type        = "Violation"
#   evaluation  = "Hourly"
#   # tags        = ["domain:AWS", "custom"]
#   enabled     = true

#   alerting {
#     enabled = true
#     profile = "LW_HA_SYSCALLS_FILE_DEFAULT_PROFILE.Violation"
#   }
# }
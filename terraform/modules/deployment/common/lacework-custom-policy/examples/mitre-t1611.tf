# resource "lacework_query" "t1611" {
#     query_id = "TF_CUSTOM_CONTAINER_MOUNT_NODE_FILESYSTEM"
#     query    = <<-EOT
#     {
#         source {
#             LW_HA_SYSCALLS_EXEC
#         }
#         filter {
#           (
#             CMDLINE LIKE '%mount %/dev/nvme0n1p1 %'
#             OR
#             CMDLINE LIKE '%mount %/dev/dm-0 %'
#             OR
#             CMDLINE LIKE '%nsenter %--mount=/proc/1/ns/mnt %-- %'
#             OR
#             (
#               PARENT_EXE_PATH LIKE '%containerd-shim-runc%' 
#               AND 
#               CMDLINE LIKE '--mount=%/mnt%'
#             )
#           )
#           AND
#           IS_IN_CONTAINER = 'true'
#         }
#         return distinct {
#             RECORD_CREATED_TIME,
#             MID,
#             PID_HASH,
#             EXE_PATH,
#             PARENT_EXE_PATH,
#             CMDLINE
#         }
#     }
#     EOT
# }

# resource "lacework_policy" "t1611" {
#   title       = "T1611: Escape to Host"
#   description = "Adversaries may break out of a container to gain access to the underlying host."
#   remediation = "Review access context and revoke keys as necessary"
#   query_id    = lacework_query.t1611.id
#   severity    = "High"
#   type        = "Violation"
#   evaluation  = "Hourly"
#   # tags        = ["domain:AWS", "custom"]
#   enabled     = true

#   alerting {
#     enabled = true
#     profile = "LW_HA_SYSCALLS_EXEC_DEFAULT_PROFILE.Violation"
#   }
# }
    
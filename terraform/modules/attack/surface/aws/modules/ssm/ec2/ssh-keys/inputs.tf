variable "environment" {
    type = string
    description = "name of the environment"
}

variable "deployment" {
    type = string
    description = "unique deployment id"
}

variable "private_tag" {
  type = string
  default = "ssm_deploy_secret_ssh_private"
}

variable "public_tag" {
  type = string
  default = "ssm_deploy_secret_ssh_public"
}

variable "timeout" {
  type = number
  default = 1200
}

variable "cron" {
  type = string
  default = "cron(0/30 * * * ? *)"
}

variable "resource_query_deploy_secret_ssh_private" {
    type    = object({
      ResourceTypeFilters = list(string)
      TagFilters  = list(object({
        Key = string
        Values = list(string)
      }))
    })
    description = "JSON query to idenfity resources which will have lacework deployed"
    default = {
                ResourceTypeFilters = [
                    "AWS::EC2::Instance"
                ]

                TagFilters = [
                    {
                        Key = "ssm_deploy_secret_ssh_private"
                        Values = [
                            "true"
                        ]
                    }
                ]
              }
}

variable "resource_query_deploy_secret_ssh_public" {
    type    = object({
      ResourceTypeFilters = list(string)
      TagFilters  = list(object({
        Key = string
        Values = list(string)
      }))
    })
    description = "JSON query to idenfity resources which will have lacework deployed"
    default = {
                ResourceTypeFilters = [
                    "AWS::EC2::Instance"
                ]

                TagFilters = [
                    {
                        Key = "ssm_deploy_secret_ssh_public"
                        Values = [
                            "true"
                        ]
                    }
                ]
              }
}

variable "ssh_public_key_path" {
    type = string
    description = "path to write ssh public key"
    default = "/home/ubuntu/.ssh/secret_key"
}

variable "ssh_private_key_path" {
    type = string
    description = "path to write ssh private key"
    default = "/home/ubuntu/.ssh/secret_key.pub"
}

variable "ssh_authorized_keys_path" {
    type = string
    description = "path to append ssh authorized key"
    default = "/home/ubuntu/.ssh/authorized_keys"
}

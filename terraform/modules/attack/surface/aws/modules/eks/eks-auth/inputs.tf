variable "environment" {
    type = string
    description = "name of the environment"
}

variable "deployment" {
    type = string
    description = "unique deployment id"
}

variable "cluster_name" {
  type    = string
}

variable "iam_eks_readers" {
    type = list(string)
    default = []
}

variable "iam_eks_admins" {
    type = list(string)
    default = []
}

variable "custom_cluster_roles" {
     type = list(object({
            enabled = bool
            name = string
            iam_user_names = list(string)
            rules = list(object({
              api_groups = list(string)
              resources = list(string)
              verbs = list(string)
            }))
          }))
    default = []
}
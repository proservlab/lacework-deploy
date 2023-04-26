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
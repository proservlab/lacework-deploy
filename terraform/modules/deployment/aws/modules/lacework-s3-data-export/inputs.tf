variable "environment" {
    type = string
    description = "name of the environment"
}

variable "deployment" {
    type = string
    description = "unique deployment id"
}


variable "read_only_iam_user_names" {
    type = list(string)
    description = "list of iam user arns that will be granted read-only access to the created s3 bucket"
    default = []
}

variable "read_only_iam_role_names" {
    type = list(string)
    description = "list of iam role arns that will be granted read-only access to the created s3 bucket"
    default = []
}

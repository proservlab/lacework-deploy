variable "inputs" {
        type = object({
            environment = string
            deployment = string
            tag = string
            listen_port = number
            db_host = string
            db_name = string
            db_user = string
            db_iam_user = string
            db_password = string
            db_port = string
            db_region = string
            db_private_ip = string
            db_public_ip = string
        })
        description = "inherit variables from the parent"
}
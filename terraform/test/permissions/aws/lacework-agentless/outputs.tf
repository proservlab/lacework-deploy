output "create_role" {
    value = var.create_role
}

output "assume_role_apply" {
    value = var.assume_role_apply
}

output "role_name" {
    value = var.role_name
}

output "default_aws_identity" {
    value = data.aws_caller_identity.current
}

output "module_identity" {
    value = coalesce(
                try(module.lacework-agentless[0].aws_identity, null),
                try(module.lacework-agentless-generated-role[0].aws_identity, {})
            )
}
output "config" {
    value = {
        context = {
            global = {
                environment               = var.config.context.global.environment
                trust_security_group      = var.config.context.global.trust_security_group
                disable_all               = var.config.context.global.disable_all
                enable_all                = var.config.context.global.enable_all
            }
            aws = {
                region                    = var.config.context.aws.region
                profile_name              = var.config.context.aws.region
                iam                       = try(module.iam[0],null)
                ec2                       = try(module.ec2[0],null)
                eks                       = try(module.eks[0],null)
                eks_instances             = data.aws_instances.cluster
            }
        }
    }
}
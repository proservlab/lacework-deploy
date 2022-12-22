output "config" {
    value = {
        context = {
            aws = {
                iam                       = try(module.iam[0],null)
                ec2                       = try(module.ec2[0],null)
                eks                       = try(module.eks[0],null)
            }
        }
    }
}
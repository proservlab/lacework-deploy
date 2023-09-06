# default execution with full admin rights
module "lacework-agentless" {
    count = var.create_role == true || var.assume_role_apply == true ? 0 : 1
    source = "./modules/lacework-agentless"
}

# execution with assume role context created via athena cloudtrail logs
module "lacework-agentless-generated-role" {
    count = var.assume_role_apply == true ? 1 : 0
    source = "./modules/lacework-agentless"
    providers = {
        aws = aws.generated_role
    }

    depends_on = [
        aws_iam_role_policy_attachment.attach_generated_policy  
    ]
}
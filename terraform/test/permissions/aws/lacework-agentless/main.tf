
# Fetch the current AWS account ID
data "aws_caller_identity" "current" {}

# Read the generated IAM policy from the JSON file
data "local_file" "generated_policy" {
    count = var.create_and_assume_role == true ? 1 : 0
    depends_on = [null_resource.trigger[0]]
    filename = var.role_policy_path
}

# Create the IAM policy using the generated JSON
resource "aws_iam_policy" "generated_policy" {
    count = var.create_and_assume_role == true ? 1 : 0
    name        = "${var.role_name}-policy"
    description = "A policy generated based on observed actions"
    policy      = data.local_file.generated_policy[0].content
}

# Create an IAM role that is assumable by the current user
resource "aws_iam_role" "generated_role" {
    count = var.create_and_assume_role == true ? 1 : 0
    name = "${var.role_name}-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
            {
                Action = "sts:AssumeRole",
                Effect = "Allow",
                Principal = {
                AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
                }
            }
        ]
    })
}

# Attach the generated policy to the role
resource "aws_iam_role_policy_attachment" "attach_generated_policy" {
    count = var.create_and_assume_role == true ? 1 : 0
    role       = aws_iam_role.generated_role[0].name
    policy_arn = aws_iam_policy.generated_policy[0].arn
}

# Define the policy to allow sts:AssumeRole
resource "aws_iam_policy" "assume_role_policy" {
    count = var.create_and_assume_role == true ? 1 : 0
    name        = "${var.role_name}-assumerole-policy"
    description = "Policy to allow user to assume role"

    policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
        {
            Action = "sts:AssumeRole",
            Effect = "Allow",
            Resource = aws_iam_role.generated_role[0].arn
        }
        ]
    })
}

# Attach the policy to the current user
resource "aws_iam_user_policy_attachment" "assume_role_policy_attachment" {
    count = var.create_and_assume_role == true ? 1 : 0
    user       = data.aws_caller_identity.current.user_id
    policy_arn = aws_iam_policy.assume_role_policy[0].arn
}

# Trigger to refresh the policy when the JSON file changes
resource "null_resource" "trigger" {
    count = var.create_and_assume_role == true ? 1 : 0
    triggers = {
        policy_hash = filemd5(var.role_policy_path)
    }
}

module "lacework-agentless" {
    count = var.create_and_assume_role == true ? 0 : 1
    source = "./modules/lacework-agentless"
}

module "lacework-agentless-generated-role" {
    count = var.create_and_assume_role == true ? 1 : 0
    source = "./modules/lacework-agentless"
    providers = {
        aws = aws.generated_role
    }

    depends_on = [
        aws_iam_user_policy_attachment.assume_role_policy_attachment,
        aws_iam_role_policy_attachment.attach_generated_policy  
    ]
}
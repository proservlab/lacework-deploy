resource "aws_instance" "instance" {
  ami           = var.ami
  instance_type = var.instance_type
  
  iam_instance_profile = var.iam_instance_profile != null ? var.iam_instance_profile : null
  
  subnet_id = var.subnet_id
  vpc_security_group_ids = var.vpc_security_group_ids
  
  tags = merge({"environment"=var.environment},{"deployment"=var.deployment},var.tags)

  user_data = var.user_data
  user_data_base64 = var.user_data_base64

  user_data_replace_on_change = true
}
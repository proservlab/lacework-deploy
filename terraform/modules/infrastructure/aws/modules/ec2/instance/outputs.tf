output "instance" {
  value = var.enable_public_ip == true ? {
    id         = aws_instance.instance.id
    name       = aws_instance.instance.tags["Name"]
    private_ip = aws_instance.instance.private_ip
    public_ip  = aws_eip.instance[0].public_ip
    ami        = aws_instance.instance.ami
    instance_type = aws_instance.instance.instance_type
    root_block_device = aws_instance.instance.root_block_device
    ebs_block_device = aws_instance.instance.ebs_block_device
    user_data = aws_instance.instance.user_data
    user_data_base64 = aws_instance.instance.user_data_base64
    vpc_id = data.aws_subnet.instance.vpc_id
    subnet_id = aws_instance.instance.subnet_id
    security_group_ids = aws_instance.instance.vpc_security_group_ids
    tags = aws_instance.instance.tags
  } : {
    id         = aws_instance.instance.id
    name       = aws_instance.instance.tags["Name"]
    private_ip = aws_instance.instance.private_ip
    public_ip  = null
    ami        = aws_instance.instance.ami
    instance_type = aws_instance.instance.instance_type
    root_block_device = aws_instance.instance.root_block_device
    ebs_block_device = aws_instance.instance.ebs_block_device
    user_data = aws_instance.instance.user_data
    user_data_base64 = aws_instance.instance.user_data_base64
    vpc_id = data.aws_subnet.instance.vpc_id
    subnet_id = aws_instance.instance.subnet_id
    security_group_ids = aws_instance.instance.vpc_security_group_ids
    tags = aws_instance.instance.tags
  }
}
locals {
  secondary_disk = "/dev/xvdb"
}

data "aws_subnet" "instance" {
  id = aws_instance.instance.subnet_id
}

resource "aws_instance" "instance" {
  ami           = var.ami
  instance_type = var.instance_type
  
  iam_instance_profile = var.iam_instance_profile != null ? var.iam_instance_profile : null
  
  subnet_id = var.subnet_id
  vpc_security_group_ids = var.vpc_security_group_ids
  
  tags = merge({"environment"=var.environment},{"deployment"=var.deployment},var.tags)

  # always send as base64
  user_data = null
  
  # build the bootrap commands from template and include additional user_data and user_data_base64 as required
  user_data_base64 = base64encode(templatefile("${path.root}/../common/payload/linux/boostrap.sh", {
    enable_secondary_volume = var.enable_secondary_volume
    secondary_disk = local.secondary_disk
    enable_swap = var.enable_swap
    additional_tasks = try(length(var.user_data), "false") != "false" ? (
      var.user_data 
    ): (
      try(length(var.user_data_base64), "false") != "false" ? (
        base64decode(var.user_data_base64) 
      ) : ( 
        ""
      )
    )
  }))

  user_data_replace_on_change = true

  root_block_device {
    volume_size    = 20
    volume_type    = "gp2"
  }
}

# secondary drive
resource "aws_ebs_volume" "secondary" {
  count = var.enable_secondary_volume == true ? 1 : 0
  availability_zone = aws_instance.instance.availability_zone
  size              = 10
  tags = merge({"Name" = "${var.tags["Name"]}-ebs"},{"environment"=var.environment},{"deployment"=var.deployment})
}

resource "aws_volume_attachment" "instance" {
  count = var.enable_secondary_volume == true ? 1 : 0
  device_name  = local.secondary_disk
  volume_id    = aws_ebs_volume.secondary[0].id
  instance_id  = aws_instance.instance.id
  force_detach = true
}

resource "aws_eip" "instance" {
  count = var.enable_public_ip == true ? 1 : 0
  domain = "vpc"
  instance = aws_instance.instance.id
}
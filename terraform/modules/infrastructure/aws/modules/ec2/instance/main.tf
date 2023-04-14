locals {
  ubuntu_secondary_disk = "/dev/xvdb"
}

resource "aws_instance" "instance" {
  ami           = var.ami
  instance_type = var.instance_type
  
  iam_instance_profile = var.iam_instance_profile != null ? var.iam_instance_profile : null
  
  subnet_id = var.subnet_id
  vpc_security_group_ids = var.vpc_security_group_ids
  
  tags = merge({"environment"=var.environment},{"deployment"=var.deployment},var.tags)

  user_data = var.user_data
  #user_data_base64 = var.user_data_base64
  user_data_base64 = var.enable_secondary_volume == true ? base64encode(
    <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt install xfsprogs -y
    sudo mkfs -t xfs ${local.ubuntu_secondary_disk}
    sudo mkdir /data
    sudo mount ${local.ubuntu_secondary_disk} /data
    BLK_ID=$(sudo blkid ${local.ubuntu_secondary_disk} | cut -f2 -d" ")
    if [[ -z $BLK_ID ]]; then
      echo "Hmm ... no block ID found ... "
      exit 1
    fi
    echo "$BLK_ID     /data   xfs    defaults   0   2" | sudo tee --append /etc/fstab
    sudo mount -a
    echo "Bootstrapping Complete!"
    EOF
  ) : var.user_data_base64

  user_data_replace_on_change = true

  root_block_device {
    volume_size    = 8
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
  device_name  = local.ubuntu_secondary_disk
  volume_id    = aws_ebs_volume.secondary[0].id
  instance_id  = aws_instance.instance.id
  force_detach = true
}
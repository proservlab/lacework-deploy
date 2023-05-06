data "aws_ami" "ubuntu_focal" {
  most_recent = true

  filter {
    name   = "name"
    # vulnerable version
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-20230301*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "aws_ami" "amazon_linux" {
  owners = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
}

locals {
    ami_map = {
        ubuntu_focal = data.aws_ami.ubuntu_focal.id
        amazon_linux = data.aws_ami.amazon_linux.id
    }
}
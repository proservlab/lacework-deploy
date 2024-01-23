data "aws_ami" "ubuntu_jammy" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "aws_ami" "ubuntu_focal" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "aws_ami" "ubuntu_bionic" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
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

data "aws_ami" "amazon_linux_20221210" {
  owners = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.20230628.0-x86_64-gp2"]
  }
}

data "aws_ami" "centos_8" {
  most_recent = true
  include_deprecated = true
  owners = ["125523088429"]
  filter {
    name   = "name"
    values = ["CentOS 8*x86_64*"]
  }
}

data "aws_ami" "centos_8_2004" {
  most_recent = true
  include_deprecated = true
  owners = ["125523088429"]
  filter {
    name   = "name"
    values = ["CentOS 8.2.2004 x86_64"]
  }
}

data "aws_ami" "rocky_linux_8" {
  most_recent = true

  filter {
    name   = "name"
    values = ["Rocky-8-ec2-*.x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["792107900819"]
}


# ami-01ca03df4a6012157

locals {
    ami_map = {
        ubuntu_focal = data.aws_ami.ubuntu_focal.id
        ubuntu_bionic = data.aws_ami.ubuntu_bionic.id
        amazon_linux = data.aws_ami.amazon_linux.id
        amazon_linux_20221210 = data.aws_ami.amazon_linux_20221210.id
        centos_8 = data.aws_ami.centos_8.id
        centos_8_2004 = data.aws_ami.centos_8_2004.id
        rocky_linux_8 = data.aws_ami.rocky_linux_8.id
    }
}
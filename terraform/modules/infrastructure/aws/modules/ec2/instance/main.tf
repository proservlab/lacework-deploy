locals {
  ubuntu_secondary_disk = "/dev/xvdb"
  enable_swap = <<-EOT
  log "enabling swap file..."
  sudo dd if=/dev/zero of=/swapfile bs=128M count=32
  log "dd swap file created..."
  log "setting swap file permissions..."
  sudo chmod 600 /swapfile
  log "running mkswap..."
  sudo mkswap /swapfile
  log "running swapon..."
  sudo swapon /swapfile
  sudo swapon -s
  log "appending swap file to fstab"
  sudo echo "/swapfile swap swap defaults 0 0" >> /etc/fstab 
  EOT
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

  user_data = var.user_data
  #user_data_base64 = var.user_data_base64
  user_data_base64 = var.enable_secondary_volume == true ? base64encode(
    <<-EOF
    #!/bin/bash
    LOGFILE=/tmp/user-data.log
    function log {
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
    }
    MAXLOG=2
    for i in `seq $((MAXLOG-1)) -1 1`; do mv "$LOGFILE."{$i,$((i+1))} 2>/dev/null || true; done
    mv $LOGFILE "$LOGFILE.1" 2>/dev/null || true
    check_package_manager() {
        pgrep -f "apt" || pgrep -f "dpkg" || pgrep -f "yum" || pgrep -f "rpm"
    }
    while check_package_manager; do
        log "Waiting for package manager to be available..."
        sleep 10
    done
    log "Starting..."
    sudo apt update -y >> $LOGFILE 2>&1
    sudo apt install xfsprogs -y >> $LOGFILE 2>&1
    sudo mkfs -t xfs ${local.ubuntu_secondary_disk} >> $LOGFILE 2>&1
    sudo mkdir /data >> $LOGFILE 2>&1
    sudo mount ${local.ubuntu_secondary_disk} /data >> $LOGFILE 2>&1
    BLK_ID=$(sudo blkid ${local.ubuntu_secondary_disk} | cut -f2 -d" ")
    log "BLK_ID: $BLK_ID"
    if [[ -z $BLK_ID ]]; then
      log "Hmm ... no block ID found ... "
      exit 1
    fi
    echo "$BLK_ID     /data   xfs    defaults   0   2" | sudo tee --append /etc/fstab
    sudo mount -a >> $LOGFILE 2>&1
    log "Creating docker directory on data drive..."
    mkdir -p /data/var/lib/docker
    ln -sf /data/var/lib/docker /var/lib/docker >> $LOGFILE 2>&1
    ${ var.enable_swap == true ? local.enable_swap : "" }
    ${try(length(var.user_data_base64), "false") != "false" ? base64decode(var.user_data_base64) : "" }
    log "Bootstrapping Complete!"
    EOF
  ) : base64encode( <<-EOF
    #!/bin/bash
    LOGFILE=/tmp/user-data.log
    function log {
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
    }
    MAXLOG=2
    for i in `seq $((MAXLOG-1)) -1 1`; do mv "$LOGFILE."{$i,$((i+1))} 2>/dev/null || true; done
    mv $LOGFILE "$LOGFILE.1" 2>/dev/null || true
    check_package_manager() {
        pgrep -f "apt" || pgrep -f "dpkg" || pgrep -f "yum" || pgrep -f "rpm"
    }
    while check_package_manager; do
        log "Waiting for package manager to be available..."
        sleep 10
    done
    log "Starting..."
    ${ var.enable_swap == true ? local.enable_swap : "" }
    ${try(length(var.user_data_base64), "false") != "false" ? base64decode(var.user_data_base64) : "" }
    log "Bootstrapping Complete!"
    EOF
  )

  user_data_replace_on_change = true

  root_block_device {
    volume_size    = 12
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

resource "aws_eip" "instance" {
  count = var.enable_public_ip == true ? 1 : 0
  domain = "vpc"
  instance = aws_instance.instance.id
}
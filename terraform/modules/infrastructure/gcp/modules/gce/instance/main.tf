data "google_compute_zones" "available" {
    region = var.gcp_location
}

locals {
    tags = {
        for key, value in var.tags : lower(key) => lower(value)
    }
    service_account_email = (var.role == "default" && var.public == true ? 
        var.public_service_account_email : var.role == "default" && var.public == false ? 
            var.private_service_account_email : var.role == "app" && var.public == true ?
                var.public_app_service_account_email : var.role == "app" && var.public == false ?
                    var.public_app_service_account_email : null)
    
    ubuntu_secondary_disk = "/dev/sdb"
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

resource "google_compute_disk" "secondary" {
    count = var.enable_secondary_volume == true ? 1 : 0
    name  = "${var.tags.name}-ebs"
    type  = "pd-standard"
    size  = 10
    zone  = data.google_compute_zones.available.names[0]
}

resource "google_compute_instance" "instance" {
    name         = var.name
    machine_type = var.instance_type
    project      = var.gcp_project_id

    zone         = data.google_compute_zones.available.names[0]

    # tags = ["foo", "bar"]

    boot_disk {
        initialize_params {
            image = var.ami
            size = 12
        }
    }

    dynamic "attached_disk" {
        for_each = var.enable_secondary_volume ? [1] : []
        content {
            source      = google_compute_disk.secondary[0].self_link
            device_name = "secondary-disk"
            mode        = "READ_WRITE"
        }
    }

    // Local SSD disk
    #   scratch_disk {
    #     interface = "SCSI"
    #   }

    network_interface {
        subnetwork              = var.subnet_id
        subnetwork_project      = var.gcp_project_id

        dynamic "access_config" {
          for_each = var.public ? [{}] : []
          content {}
        }
    }

    metadata = {
        enable-osconfig = "true"
        enable-oslogin = "true"
        osconfig-log-level= "debug"
    }

    # converted label keys to lower
    labels = local.tags

    metadata_startup_script = var.enable_secondary_volume == true ? (
        <<-EOF
        #!/bin/bash
        LOGFILE=/tmp/user-data.log
        function log {
            echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
            echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
        }
        truncate -s 0 $LOGFILE
        check_apt() {
            pgrep -f "apt" || pgrep -f "dpkg"
        }
        while check_apt; do
            log "Waiting for apt to be available..."
            sleep 10
        done
        log "Starting..."
        sudo apt update -y >> $LOGFILE 2>&1
        sudo apt-get install -y google-osconfig-agent >> $LOGFILE 2>&1
        sudo apt-get install -y xfsprogs -y >> $LOGFILE 2>&1
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
    ) : ( 
        <<-EOF
        #!/bin/bash
        LOGFILE=/tmp/user-data.log
        function log {
            echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
            echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
        }
        truncate -s 0 $LOGFILE
        check_apt() {
            pgrep -f "apt" || pgrep -f "dpkg"
        }
        while check_apt; do
            log "Waiting for apt to be available..."
            sleep 10
        done
        log "Starting..."
        sudo apt update -y >> $LOGFILE 2>&1
        sudo apt-get install -y google-osconfig-agent >> $LOGFILE 2>&1
        ${ var.enable_swap == true ? local.enable_swap : "" }
        ${try(length(var.user_data_base64), "false") != "false" ? base64decode(var.user_data_base64) : "" }
        log "Bootstrapping Complete!"
        EOF
    )

    service_account {
        # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
        email  = local.service_account_email
        scopes = ["https://www.googleapis.com/auth/servicecontrol",
                  "https://www.googleapis.com/auth/service.management.readonly",
                  "https://www.googleapis.com/auth/logging.write",
                  "https://www.googleapis.com/auth/monitoring.write",
                  "https://www.googleapis.com/auth/trace.append",
                  "https://www.googleapis.com/auth/devstorage.read_only",
                  "https://www.googleapis.com/auth/cloud.useraccounts.readonly"]
    }
}
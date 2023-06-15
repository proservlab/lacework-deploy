data "google_compute_zones" "available" {
    region = var.gcp_location
}

locals {
    tags = {
        for key, value in var.tags : lower(key) => lower(value)
    }
    startup = templatefile(
                            "${path.module}/resources/startup.sh",
                            {} 
                        )
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

    metadata_startup_script = can(length(var.user_data)) ? var.user_data : local.startup

    service_account {
        # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
        email  = var.service_account_email
        scopes = ["cloud-platform"]
    }
}
data "template_file" "startup" {
    template = file("${path.module}/resources/startup.sh")
    vars = {}
}

resource "google_compute_instance" "instance" {
    name         = "${var.environment}-${var.deployment}-compute"
    machine_type = var.instance_type
    zone         = "us-central1-a"

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
        subnetwork = var.subnet_id

        dynamic "access_config" {
          for_each = var.public ? [{}] : []
          content {}
        }
    }

    metadata = {
        enable-osconfig = "true"
    }

    labels = var.tags

    metadata_startup_script = can(length(var.user_data)) ? var.user_data : data.template_file.startup.rendered

    service_account {
        # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
        email  = var.service_account_email
        scopes = ["cloud-platform"]
    }
}
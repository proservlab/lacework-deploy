resource "google_service_account" "default" {
    account_id   = "${var.environment}-gce-service-account"
    display_name = "${var.environment}-gce-service-account"
}

data "template_file" "startup" {
    template = file("${path.module}/startup.sh")
    vars = {
        foo = "bar"
    }
}

resource "google_compute_instance" "default" {
    name         = "${var.environment}-compute"
    machine_type = "e2-micro"
    zone         = "us-central1-a"

    tags = ["foo", "bar"]

    boot_disk {
        initialize_params {
            image = "debian-cloud/debian-11"
        }
    }

    // Local SSD disk
    #   scratch_disk {
    #     interface = "SCSI"
    #   }

    network_interface {
        network = "default"

        access_config {
        // Ephemeral public IP
        }
    }

    metadata = {
        foo = "bar"
        enable-osconfig = "true"
    }

    labels = {
        enable-osconfig = "true"
    }

    metadata_startup_script = data.template_file.startup.rendered

    service_account {
        # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
        email  = google_service_account.default.email
        scopes = ["cloud-platform"]
    }
}
data "template_file" "startup" {
    template = file("${path.module}/resources/startup.sh")
    vars = {}
}

# resource "google_compute_instance" "instance" {
#     name         = "${var.environment}-${var.deployment}-compute"
#     machine_type = "e2-micro"
#     zone         = "us-central1-a"

#     # tags = ["foo", "bar"]

#     boot_disk {
#         initialize_params {
#             image = "debian-cloud/debian-11"
#         }
#     }

#     // Local SSD disk
#     #   scratch_disk {
#     #     interface = "SCSI"
#     #   }

#     network_interface {
#         subnetwork = var.subnet_id
#         network = "default"

#         access_config {
#         // Ephemeral public IP
#         }
#     }

#     metadata = {
#         enable-osconfig = "true"
#     }

#     labels = var.tags

#     metadata_startup_script = can(length(var.user_data)) ? var.user_data : data.template_file.startup.rendered

#     service_account {
#         # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
#         email  = var.service_account_email
#         scopes = ["cloud-platform"]
#     }
# }
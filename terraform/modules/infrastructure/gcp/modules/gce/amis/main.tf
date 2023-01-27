data "google_compute_image" "ubuntu_focal" {
  family  = "ubuntu-2004-lts"
  project = "ubuntu-os-cloud"
}

data "google_compute_image" "debian_11" {
  family  = "debian-11"
  project = "debian-cloud"
}

locals {
    ami_map = {
        ubuntu_focal = data.google_compute_image.ubuntu_focal.self_link
        debian_11 = data.google_compute_image.debian_11.self_link
    }
}
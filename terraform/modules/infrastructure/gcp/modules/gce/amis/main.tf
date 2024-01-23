data "google_compute_image" "ubuntu_focal" {
  family  = "ubuntu-2004-lts"
  project = "ubuntu-os-cloud"
}

data "google_compute_image" "debian_11" {
  family  = "debian-11"
  project = "debian-cloud"
}

data "google_compute_image" "centos8" {
  project = "centos-cloud"
  family = "centos-stream-8"
}

data "google_compute_image" "centos8_20191002" {
  name    = "centos-8-v20191002"
  project = "centos-cloud"
  family = "centos-stream-8"
}

data "google_compute_image" "rocky_linux_8" {
  project = "rocky-linux-cloud"
  family = "rocky-linux-8"
}

locals {
    ami_map = {
        ubuntu_focal = data.google_compute_image.ubuntu_focal.self_link
        debian_11 = data.google_compute_image.debian_11.self_link
        centos8 = data.google_compute_image.centos8.self_link
        centos8_20191002 = data.google_compute_image.centos8_20191002.self_link
        rocky_linux_8 = data.google_compute_image.rocky_linux_8.self_link
    }
}
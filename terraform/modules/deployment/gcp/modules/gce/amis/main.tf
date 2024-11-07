data "google_compute_image" "ubuntu_focal" {
  family  = "ubuntu-2004-lts"
  project = "ubuntu-os-cloud"
}

data "google_compute_image" "debian_11" {
  family  = "debian-11"
  project = "debian-cloud"
}


data "google_compute_image" "rocky_linux_8" {
  project = "rocky-linux-cloud"
  family = "rocky-linux-8"
}

data "google_compute_image" "windows_2019" {
  project = "windows-cloud"
  family = "windows-2019"
}

data "google_compute_image" "windows_2022" {
  project = "windows-cloud"
  family = "windows-2022"
}


locals {
    ami_map = {
        ubuntu_focal = data.google_compute_image.ubuntu_focal.self_link
        debian_11 = data.google_compute_image.debian_11.self_link
        rocky_linux_8 = data.google_compute_image.rocky_linux_8.self_link
        windows_2019 = data.google_compute_image.windows_2019.self_link
    }
}
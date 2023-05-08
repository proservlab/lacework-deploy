terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.15"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

resource "null_resource" "build_custom_ctfd_image" {
  provisioner "local-exec" {
    command = "docker build -t my-custom-ctfd ."
  }

  triggers = {
    always_run = timestamp()
  }
}

resource "docker_image" "custom_ctfd" {
  name = "my-custom-ctfd:latest"

  depends_on = [null_resource.build_custom_ctfd_image]
}

resource "docker_container" "ctfd" {
  image        = docker_image.custom_ctfd.latest
  name         = "ctfd"
  restart      = "no"
  must_run     = true
  user         = "1001:1001"
  hostname     = "ctfd"
  rm           = false
  start        = true
  attach       = false
  stdin_open   = false
  tty          = false
  ipc_mode     = "private"
  network_mode = "bridge"

  ports {
    internal = 8000
    external = 8000
  }

  volumes {
    host_path      = "${path.cwd}/ctfd_data"
    container_path = "/opt/CTFd/.data"
  }


  volumes {
    host_path      = "${path.cwd}/api_tokens"
    container_path = "/api_tokens"
  }
}


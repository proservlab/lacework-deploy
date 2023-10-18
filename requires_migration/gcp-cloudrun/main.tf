terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "~> 4.84"
    }
    docker = {
      source = "kreuzwerker/docker"
      version = "3.0.1"
    }
    lacework = {
      source  = "lacework/lacework"
      version = "~> 1.4"
    }
  }
}

provider "lacework" {
    profile = var.lacework_profile
}

provider "google" {
  project = var.gcp_project_id
  region = var.gcp_location
}

provider "docker" {
  registry_auth {
    address     = "gcr.io"
    config_file = pathexpand("~/.docker/config.json")
  }
}

resource "lacework_agent_access_token" "cloudrun" {
  name        = "gcp-cloudrun-${var.environment}-${var.deployment}"
  description = "Cloudrun agent token"
}

data "lacework_user_profile" "current" { }

data "google_container_registry_repository" "repo" {
    project  = var.gcp_project_id
}

resource "null_resource" "docker_auth" {
  triggers = {
    hash = timestamp()
  }

  provisioner "local-exec" {
    command     =   <<-EOT
                    gcloud auth configure-docker gcr.io
                    EOT
    interpreter = ["bash", "-c"]
  }
}

resource "docker_image" "image" {
  name = "${data.google_container_registry_repository.repo.repository_url}/${var.image_name}:${var.tag}"
  build {
    context = "."
  }

  triggers = {
    dir_sha1 = sha1(join("", [for f in fileset(path.module, "src/*") : filesha1(f)]))
  }

  depends_on = [
    null_resource.docker_auth
  ]
}

resource "docker_registry_image" "app" {
  name          = docker_image.image.name
  keep_remotely = true
  triggers = {
    "repo_digest" = docker_image.image.repo_digest
  }
}

resource "google_cloud_run_service" "default" {
  name     = "test"
  location = var.gcp_location

  template {
    spec {
      containers {
        image = "${docker_image.image.name}"
        ports {
          name = "http1"
          container_port = 8000
        }
        env {
          name = "LaceworkServerUrl"
          value = "https://${data.lacework_user_profile.current.url}"
        }
        env {
          name = "LaceworkAccessToken"
          value = lacework_agent_access_token.cloudrun.token
        }
        env {
          name = "LW_CLOUDRUN_ENV_GEN"
          value = var.LW_CLOUDRUN_ENV_GEN
        }
      }
      service_account_name = google_service_account.webserverapp.email
    }
    metadata {
      annotations = {
        "run.googleapis.com/cpu-throttling": "false"
        "run.googleapis.com/execution-environment" = var.LW_CLOUDRUN_ENV_GEN
      }
    }
  }

  depends_on = [
    docker_registry_image.app
  ]
}

resource "google_service_account" "webserverapp" {
  provider     = google-beta
  project      = var.gcp_project_id
  account_id   = "webserverapp-identity"
  display_name = "service account name to display in Google Cloud console"
}

data "google_iam_policy" "apppolicy" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
  binding {
    role = "roles/run.viewer"
    members = [
     "serviceAccount:${google_service_account.webserverapp.email}",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "servicepolicy" {
  location    = google_cloud_run_service.default.location
  project     = google_cloud_run_service.default.project
  service     = google_cloud_run_service.default.name
  policy_data = data.google_iam_policy.apppolicy.policy_data
}

output "service_url" {
  value = google_cloud_run_service.default.status[0].url
}

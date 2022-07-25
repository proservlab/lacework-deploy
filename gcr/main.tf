terraform {
  required_providers {
    lacework = {
      source = "lacework/lacework"
      version = "~> 0.22.1"
    }
  }
}

data "google_project" "project" {}

data "google_projects" "projects" {
  filter = "parent.id:${data.google_project.project.org_id} lifecycleState:ACTIVE"
}

provider "lacework" {
  profile="proservlab"
}

provider "google" {}

module "lacework_gcr" {
  source  = "lacework/gcr/gcp"
  version = "~> 2.3.0"
  for_each   = { 
    for index, project in data.google_projects.projects.projects: project.project_id => project
  }
  project_id = each.value.project_id
  
  lacework_integration_name = each.value.project_id

  non_os_package_support="true"
  limit_num_imgs="15"
}
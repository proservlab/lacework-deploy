provider "google" {
  region = "us-central1"
  project = "kubernetes-cluster-331006"
  credentials = file("~/.config/gcloud/terraform-automation.json")
}


module "gcp" {
  source = "../../gcp"
  project_id = "kubernetes-cluster-331006"
  cluster_username = ""
  cluster_password = ""
  sql_enabled = false
  sql_master_username = ""
  sql_master_password = ""
  environment_name = "test"
  region = "us-central1"
  nodes_max_size = 2
  nodes_min_size = 1
  nodes_desired_capacity = 2
}


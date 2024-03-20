resource "null_resource" "target_eks_context_switcher" {
  count = local.target_infrastructure_config.context.aws.eks.enabled ? 1 : 0
  triggers = {
    always = timestamp()
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<-EOT
                echo 'Applying Auth ConfigMap with kubectl...'
                aws eks wait cluster-active --profile '${var.target_aws_profile}' --region=${var.target_aws_region} --name '${module.target-eks[0].cluster.name}'
                if ! command -v yq; then
                  curl -LJ https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /usr/local/bin/yq &&\
                  chmod +x /usr/local/bin/yq
                fi
                aws eks update-kubeconfig --profile '${var.target_aws_profile}' --name '${module.target-eks[0].cluster.name}' --region=${var.target_aws_region}
                aws eks update-kubeconfig --profile '${var.target_aws_profile}' --name '${module.target-eks[0].cluster.name}' --region=${var.target_aws_region} --kubeconfig="${pathexpand(module.target-eks[0].kubeconfig_path)}"
                yq -i -r '(.users[] | select(.name == "${module.target-eks[0].cluster.arn}")|.user.exec.env[0].name) = "AWS_PROFILE"' -i "${pathexpand(module.target-eks[0].kubeconfig_path)}"
                yq -i -r '(.users[] | select(.name == "${module.target-eks[0].cluster.arn}")|.user.exec.env[0].value) = "${var.target_aws_profile}"' -i "${pathexpand(module.target-eks[0].kubeconfig_path)}"
                yq -i -r '(.users[] | select(.name == "${module.target-eks[0].cluster.arn}")|.user.exec.env[1].name) = "AWS_REGION"' -i "${pathexpand(module.target-eks[0].kubeconfig_path)}"
                yq -i -r '(.users[] | select(.name == "${module.target-eks[0].cluster.arn}")|.user.exec.env[1].value) = "${var.target_aws_region}"' -i "${pathexpand(module.target-eks[0].kubeconfig_path)}"
                yq -i -r '(.users[] | select(.name == "${module.target-eks[0].cluster.arn}")|.user.exec.env[0].name) = "AWS_PROFILE"' -i "${pathexpand("~/.kube/config")}"
                yq -i -r '(.users[] | select(.name == "${module.target-eks[0].cluster.arn}")|.user.exec.env[0].value) = "${var.attacker_aws_profile}"' -i "${pathexpand("~/.kube/config")}"
                yq -i -r '(.users[] | select(.name == "${module.target-eks[0].cluster.arn}")|.user.exec.env[1].name) = "AWS_REGION"' -i "${pathexpand("~/.kube/config")}"
                yq -i -r '(.users[] | select(.name == "${module.target-eks[0].cluster.arn}")|.user.exec.env[1].value) = "${var.attacker_aws_region}"' -i "${pathexpand("~/.kube/config")}"
              EOT
  }

  depends_on = [ 
    module.target-eks
  ]
}

resource "null_resource" "attacker_eks_context_switcher" {
  count = local.attacker_infrastructure_config.context.aws.eks.enabled ? 1 : 0
  triggers = {
    always = timestamp()
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<-EOT
                echo 'Applying Auth ConfigMap with kubectl...'
                aws eks wait cluster-active --profile '${var.attacker_aws_profile}' --region=${var.attacker_aws_region} --name '${module.attacker-eks[0].cluster.name}'
                if ! command -v yq; then
                  curl -LJ https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /usr/local/bin/yq &&\
                  chmod +x /usr/local/bin/yq
                fi
                aws eks update-kubeconfig --profile '${var.attacker_aws_profile}' --name '${module.attacker-eks[0].cluster.name}' --region=${var.attacker_aws_region}
                aws eks update-kubeconfig --profile '${var.attacker_aws_profile}' --name '${module.attacker-eks[0].cluster.name}' --region=${var.attacker_aws_region} --kubeconfig="${pathexpand(module.attacker-eks[0].kubeconfig_path)}"
                yq -i -r '(.users[] | select(.name == "${module.attacker-eks[0].cluster.arn}")|.user.exec.env[0].name) = "AWS_PROFILE"' -i "${pathexpand(module.attacker-eks[0].kubeconfig_path)}"
                yq -i -r '(.users[] | select(.name == "${module.attacker-eks[0].cluster.arn}")|.user.exec.env[0].value) = "${var.attacker_aws_profile}"' -i "${pathexpand(module.attacker-eks[0].kubeconfig_path)}"
                yq -i -r '(.users[] | select(.name == "${module.attacker-eks[0].cluster.arn}")|.user.exec.env[1].name) = "AWS_REGION"' -i "${pathexpand(module.attacker-eks[0].kubeconfig_path)}"
                yq -i -r '(.users[] | select(.name == "${module.attacker-eks[0].cluster.arn}")|.user.exec.env[1].value) = "${var.attacker_aws_region}"' -i "${pathexpand(module.attacker-eks[0].kubeconfig_path)}"
                yq -i -r '(.users[] | select(.name == "${module.attacker-eks[0].cluster.arn}")|.user.exec.env[0].name) = "AWS_PROFILE"' -i "${pathexpand("~/.kube/config")}"
                yq -i -r '(.users[] | select(.name == "${module.attacker-eks[0].cluster.arn}")|.user.exec.env[0].value) = "${var.attacker_aws_profile}"' -i "${pathexpand("~/.kube/config")}"
                yq -i -r '(.users[] | select(.name == "${module.attacker-eks[0].cluster.arn}")|.user.exec.env[1].name) = "AWS_REGION"' -i "${pathexpand("~/.kube/config")}"
                yq -i -r '(.users[] | select(.name == "${module.attacker-eks[0].cluster.arn}")|.user.exec.env[1].value) = "${var.attacker_aws_region}"' -i "${pathexpand("~/.kube/config")}"
              EOT
  }

  depends_on = [ 
    module.attacker-eks
  ]
}

data "local_file" "attacker_kubeconfig" {
  count = local.attacker_infrastructure_config.context.aws.eks.enabled ? 1 : 0
  filename = pathexpand(module.attacker-eks[0].kubeconfig_path)
  depends_on = [
    null_resource.attacker_eks_context_switcher,
    module.attacker-eks
  ]
}

data "local_file" "target_kubeconfig" {
  count = local.target_infrastructure_config.context.aws.eks.enabled ? 1 : 0
  filename = pathexpand(module.target-eks[0].kubeconfig_path)
  depends_on = [
    null_resource.target_eks_context_switcher,
    module.target-eks
  ]
}

provider "kubernetes" {
  alias = "attacker"
  host = module.attacker-eks.cluster.endpoint
  cluster_ca_certificate = base64decode(module.attacker-eks.cluster.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args = ["eks", "get-token", "--profile", var.attacker_aws_profile, "--cluster-name", module.attacker-eks.cluster.id]
    command = "aws"
  }
}

# provider "kubernetes" {
#   alias = "attacker"
#   config_path = local.attacker_infrastructure_config.context.aws.eks.enabled ? data.local_file.attacker_kubeconfig[0].filename : local.attacker_kubeconfig
# }

provider "kubernetes" {
  alias = "target"
  host = module.target-eks.cluster.endpoint
  cluster_ca_certificate = base64decode(module.target-eks.cluster.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args = ["eks", "get-token", "--profile", var.target_aws_profile, "--cluster-name", module.target-eks.cluster.id]
    command = "aws"
  }
}

# provider "kubernetes" {
#   alias = "target"
#   config_path = local.target_infrastructure_config.context.aws.eks.enabled ? data.local_file.target_kubeconfig[0].filename : local.target_kubeconfig
# }

provider "helm" {
  alias = "attacker"
  kubernetes {
    host = module.attacker-eks.cluster.endpoint
    cluster_ca_certificate = base64decode(module.attacker-eks.cluster.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args = ["eks", "get-token", "--profile", var.attacker_aws_profile, "--cluster-name", module.attacker-eks.cluster.id]
      command = "aws"
    }
  }
}

# provider "helm" {
#   alias = "attacker"
#   kubernetes {
#     config_path = local.attacker_infrastructure_config.context.aws.eks.enabled ? data.local_file.attacker_kubeconfig[0].filename : local.attacker_kubeconfig
#   }
# }

provider "helm" {
  alias = "target"
  kubernetes {
    host = module.target-eks.cluster.endpoint
    cluster_ca_certificate = base64decode(module.target-eks.cluster.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args = ["eks", "get-token", "--profile", var.target_aws_profile, "--cluster-name", module.target-eks.cluster.id]
      command = "aws"
    }
  }
}

# provider "helm" {
#   alias = "target"
#   kubernetes {
#     config_path = local.target_infrastructure_config.context.aws.eks.enabled ? data.local_file.target_kubeconfig[0].filename : local.target_kubeconfig
#   }
# }

provider "aws" { 
  profile = var.target_aws_profile
  region = var.target_aws_region
}

provider "aws" {
  alias = "attacker"
  profile = var.attacker_aws_profile
  region = var.attacker_aws_region
}

provider "aws" {
  alias = "target"
  profile = var.target_aws_profile
  region = var.target_aws_region
}

provider "lacework" {
  alias      = "attacker"
  profile    = var.attacker_lacework_profile
}

provider "lacework" {
  alias      = "target"
  profile    = var.target_lacework_profile
}

provider "restapi" {
  alias = "main"
  uri                  = "https://api.dynu.com/v2"
  write_returns_object = true
  debug                = true
  id_attribute         = "id"
  timeout              = 600

  headers = {
    API-Key = var.dynu_api_key
    Content-Type = "application/json"
    accept = "application/json"
    Cache-Control =  "no-cache, no-store"
    User-Agent = "curl/8.4.0"
  }

  create_method  = "POST"
  update_method  = "POST"
  destroy_method = "DELETE"
}
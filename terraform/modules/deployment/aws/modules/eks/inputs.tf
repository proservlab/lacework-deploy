variable "environment" {
    type = string
    description = "name of the environment"
}

variable "deployment" {
    type = string
    description = "unique deployment id"
}

variable region {
  type  = string
}

variable "cluster_name" {
  type    = string
}

variable "cluster_version" {
  type    = string
  default = "1.29"
}

variable "aws_profile_name" {
  description = "aws profile name"
  type        = string
}

variable "public_access_cidr" {
  type        = list
  description = "public ip address cidr allowed to access kubernetes api (default: [ '0.0.0.0/0' ])"
  default     = [ "0.0.0.0/0" ]
}

variable "kubeconfig_path" {
  type = string
  description = "kubeconfig path"
}

variable "deploy_calico" {
  type = bool
  description = "enable eks calico deployment"
}

# aws eks describe-addon-versions --addon-name aws-ebs-csi-driver --kubernetes-version <KUBERNETES VERSION> \
# --query "addons[].addonVersions[].[addonVersion, compatibilities[].defaultVersion]" --output text
variable "addons" {
  type = list(object({
    name    = string
    version = string
  }))

  default = [
    {
      name    = "kube-proxy"
      version = "v1.29.0-eksbuild.1"
    },
    {
      name    = "vpc-cni"
      version = "v1.16.0-eksbuild.1"
    },
    {
      name    = "coredns"
      version = "v1.11.1-eksbuild.4"
    },
    {
      name    = "aws-ebs-csi-driver"
      version = "v1.26.1-eksbuild.1"
    }
  ]
}

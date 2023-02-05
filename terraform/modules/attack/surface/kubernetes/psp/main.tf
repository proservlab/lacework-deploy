##################################################
# MODULE ID
##################################################

module "id" {
  source = "../../../../context/deployment"
}

resource "kubernetes_pod_security_policy" "privileged" {
  metadata {
    name = "privileged"
    annotations = {
        "seccomp.security.alpha.kubernetes.io/allowedProfileNames" : "*"
    }
        
  }
  spec {
    privileged                 = true
    allow_privilege_escalation = true
    allowed_capabilities = ["*"]

    volumes = [
      "*",
    ]

    host_network = true
    host_ports {
      min = 0
      max = 65535
    }
    host_ipc = true
    host_pid = true

    run_as_user {
      rule = "RunAsAny"
    }

    se_linux {
      rule = "RunAsAny"
    }

    supplemental_groups {
      rule = "RunAsAny"
    }

    fs_group {
      rule = "RunAsAny"
    }
  }
}

resource "kubernetes_pod_security_policy" "restricted" {
  metadata {
    name = "restricted"
    annotations = {
        "seccomp.security.alpha.kubernetes.io/allowedProfileNames" : "docker/default"
        "seccomp.security.alpha.kubernetes.io/defaultProfileName" : "docker/default"
    }
  }
  spec {
    privileged                 = false
    # Required to prevent escalations to root.
    allow_privilege_escalation = false

    # This is redundant with non-root + disallow privilege escalation,
    # but we can provide it for defense in depth
    required_drop_capabilities = [ "ALL"]

    volumes = [
        "configMap",
        "emptyDir",
        "projected",
        "secret",
        "downwardAPI",
        "persistentVolumeClaim",
    ]

    host_network = false
    host_ipc = false
    host_pid = false

    run_as_user {
        # Require the container to run without root privileges.
        rule = "MustRunAsNonRoot"
    }

    se_linux {
        rule = "RunAsAny"
    }

    supplemental_groups {
        rule = "MustRunAs"
        # Forbid adding the root group.
        range {
            min = 1
            max = 65535
        }
    }

    fs_group {
        rule = "MustRunAs"
        # Forbid adding the root group.
        range {
            min = 1
            max = 65535
        }
    }

    read_only_root_filesystem = false
  }
}

resource "kubernetes_cluster_role" "privileged" {
  metadata {
    name = "psp:privileged"
  }

  rule {
    api_groups = ["extensions"]
    resources  = ["podsecuritypolicies"]
    verbs      = ["use"]
    resource_names = ["privileged"]
  }
}

resource "kubernetes_cluster_role" "restricted" {
  metadata {
    name = "psp:restricted"
  }

  rule {
    api_groups = ["extensions"]
    resources  = ["podsecuritypolicies"]
    verbs      = ["use"]
    resource_names = ["restricted"]
  }
}

resource "kubernetes_cluster_role_binding" "default" {
  metadata {
    name = "default:privileged"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "psp:privileged"
  }
  subject {
    kind      = "Group"
    name      = "system:serviceaccounts:cert-manager"
    api_group = "rbac.authorization.k8s.io"
  }
  subject {
    kind      = "Group"
    name      = "system:serviceaccounts:concourse"
    api_group = "rbac.authorization.k8s.io"
  }
  subject {
    kind      = "Group"
    name      = "system:serviceaccounts:ingress-controllers"
    api_group = "rbac.authorization.k8s.io"
  }
  subject {
    kind      = "Group"
    name      = "system:serviceaccounts:kuberos"
    api_group = "rbac.authorization.k8s.io"
  }
  subject {
    kind      = "Group"
    name      = "system:serviceaccounts:logging"
    api_group = "rbac.authorization.k8s.io"
  }
  subject {
    kind      = "Group"
    name      = "system:serviceaccounts:monitoring"
    api_group = "rbac.authorization.k8s.io"
  }
  subject {
    kind      = "Group"
    name      = "system:serviceaccounts:kiam"
    api_group = "rbac.authorization.k8s.io"
  }
  subject {
    kind      = "Group"
    name      = "system:serviceaccounts:opa"
    api_group = "rbac.authorization.k8s.io"
  }
}
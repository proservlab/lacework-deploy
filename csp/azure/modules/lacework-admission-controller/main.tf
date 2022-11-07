# module "lacework_admission_controller" {
#   source  = "lacework/admission-controller/kubernetes"
#   version = "~> 0.1"

#   lacework_account_name = "${var.lacework_account_name}"
#   proxy_scanner_token   = "${var.proxy_token}"
#   default_registry      = "index.docker.io"
#   static_cache_location = "/opt/lacework"
#   scan_public_registries = true

#   registries = [
#     {
#       name      = "docker_public"
#       domain    = "index.docker.io"
#       ssl       = true
#       auto_poll = false
#       is_public = true
#       disable_non_os_package_scanning = false
#     },
#     {
#       name      = "github_public"
#       domain    = "ghcr.io"
#       ssl       = true
#       auto_poll = false
#       is_public = true
#       disable_non_os_package_scanning = false
#       notification_type = "ghcr"
#     }
#   ]
# }

resource "tls_private_key" "ca" {
  count     = var.use_self_signed_certs ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "ca" {
  count                 = var.use_self_signed_certs ? 1 : 0
  private_key_pem       = tls_private_key.ca[0].private_key_pem
  validity_period_hours = 2400000
  is_ca_certificate     = true
  allowed_uses = [
    "cert_signing",
    "key_encipherment",
    "digital_signature",
  ]
  subject {
    common_name = "admission_ca"
  }
}

resource "tls_private_key" "admission" {
  count     = var.use_self_signed_certs ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "admission" {
  count           = var.use_self_signed_certs ? 1 : 0
  private_key_pem = tls_private_key.admission[0].private_key_pem
  dns_names = [
    join(".", [var.admission_controller_name, var.namespace, "svc"]),
    join(".", [var.admission_controller_name, var.namespace, "svc", "cluster", "local"]),
    "admission.lacework-dev.svc",
    "admission.lacework-dev.svc.cluster.local",
  ]
  subject {
    common_name = "lacework-admission-controller.lacework.svc"
  }
}

resource "tls_locally_signed_cert" "admission" {
  count           = var.use_self_signed_certs ? 1 : 0
  allowed_uses = [
    "cert_signing",
    "key_encipherment",
    "digital_signature",
    "client_auth",
    "server_auth"
  ]
  ca_cert_pem           = tls_self_signed_cert.ca[0].cert_pem
  ca_private_key_pem    = tls_private_key.ca[0].private_key_pem
  cert_request_pem      = tls_cert_request.admission[0].cert_request_pem
  validity_period_hours = 2400000
}

data "template_file" "values" {
  template = "${file("${path.module}/resources/values.yaml.tpl")}"

  vars = {
    lacework_account_name = "${var.lacework_account_name}"
    proxy_token = "${var.proxy_token}"
  }
}

resource "helm_release" "admission-controller" {
    name       = "lacework-admission-controller"
    repository = "https://lacework.github.io/helm-charts"
    chart      = "admission-controller"

    create_namespace =  false
    namespace = "lacework"
    force_update = true
    
    values = [data.template_file.values.rendered]

    set {
        name  = "webhooks.caBundle"
        value = base64encode(tls_self_signed_cert.ca[0].cert_pem)
    }

    set {
        name  = "certs.serverCertificate"
        value = base64encode(tls_locally_signed_cert.admission[0].cert_pem)
    }

    set {
        name  = "certs.serverKey"
        value = base64encode(tls_private_key.admission[0].private_key_pem)
    }

    set {
        name  = "scanner.skipVerify"
        value = false
    }

    set {
        name  = "scanner.caCert"
        value = base64encode(tls_self_signed_cert.ca[0].cert_pem)
    }

    set {
        name  = "proxy-scanner.certs.skipCert"
        value = false
    }

    set {
        name  = "proxy-scanner.certs.serverCertificate"
        value = base64encode(tls_locally_signed_cert.admission[0].cert_pem)
    }

    set {
        name  = "proxy-scanner.certs.serverKey"
        value = base64encode(tls_private_key.admission[0].private_key_pem) 
    }
}
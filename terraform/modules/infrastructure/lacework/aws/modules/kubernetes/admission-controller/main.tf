resource "random_uuid" "proxyscanner" {
}

resource "lacework_integration_proxy_scanner" "proxyscanner" {
  # count = can(length(var.lacework_proxy_token)) ? 0 : 1
  name = "proxyscanner-access-token-${var.environment}-${var.deployment}"
}

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

locals {
    values = templatefile(
                            "${path.module}/resources/values.yaml.tpl",
                            {
                              lacework_account_name = var.lacework_account_name
                              # lacework_proxy_token = can(length(var.lacework_proxy_token)) ? var.lacework_proxy_token : lacework_integration_proxy_scanner.proxyscanner[0].server_token
                              lacework_proxy_token = lacework_integration_proxy_scanner.proxyscanner.server_token
                            }
                          )
}

resource "helm_release" "admission-controller" {
    name       = "lacework-admission-controller-${var.environment}-${var.deployment}"
    repository = "https://lacework.github.io/helm-charts"
    chart      = "admission-controller"

    create_namespace =  false
    namespace = "lacework"
    force_update = true
    
    values = [local.values]

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
provider "lacework" {
    profile="snifftest-rbac"
}

provider "aws" {
  region = var.region
  profile="proservlab"
}

# hash the certs directory - not used currently
data "external" "hash" {
  program = [coalesce(var.hash_script, "${path.module}/hash.sh"), var.source_path]
}

data "template_file" "values" {
  template = "${file("${path.module}/values.yaml.tpl")}"
  vars = {
    proxy_token = "${var.proxy_token}"
    lacework_account_name = "${var.lacework_account_name}"
  }
}

resource "helm_release" "lacework-admission-controller" {
    name       = "lacework-admission-controller"
    repository = "https://lacework.github.io/helm-charts"
    chart      = "admission-controller"

    create_namespace =  false
    namespace =  "lacework"
    force_update = true

    set {
        name  = "webhooks.caBundle"
        value = file("${path.module}/certs/ca.crt_b64")
    }

    set {
        name  = "certs.serverCertificate"
        value = file("${path.module}/certs/admission.crt_b64")
    }

    set {
        name  = "certs.serverKey"
        value = file("${path.module}/certs/admission.key_b64")
    }

    # set {
    #     name  = "scanner.skipVerify"
    #     value = true
    # }

    # set {
    #     name  = "scanner.caCert"
    #     value = file("${path.module}/certs/ca.crt_b64")
    # }

    # set {
    #     name  = "proxy-scanner.certs.skipCert"
    #     value = true
    # }

    # set {
    #     name  = "proxy-scanner.certs.serverCertificate"
    #     value = file("${path.module}/certs/admission.crt_b64")
    # }

    # set {
    #     name  = "proxy-scanner.certs.serverKey"
    #     value = file("${path.module}/certs/admission.key_b64")
    # }

    values = [
      "${data.template_file.values.rendered}"
    ]
}
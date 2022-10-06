data "lacework_api_token" "proxy" { }

resource "null_resource" "proxy-token-setup" {
  provisioner "local-exec" {
      command = "${path.module}/proxy_token_setup.py -a ${data.aws_caller_identity.current.account_id} -t aws_role"
  }

  depends_on = ["data.lacework_api_token.proxy"]
}
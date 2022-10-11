# this example requires a lacework role and external id in each cloud account

variable "accounts" {
  description = "Map of accounts and external IDs to configure with Lacework."
  type        = map(any)
  # Adjust the following map to match your own accounts. The key can be a short 
  # identifier of your choice, like the account alias or nickname.
  default = {
    account0 = [ "797545041199", "54f1d7c0-5a93-11eb-8b8a-0ab7a5ca10f9" ]
    account1 = [ "998539424818", "66a083e0-5a93-11eb-a3f0-0684b54475c9" ]
    account2 = [ "029076012049", "43036380-5a93-11eb-b0ab-0a9226e9facd" ]
  }
}

resource "lacework_integration_aws_cfg" "all_accounts" {
  for_each                  = var.accounts
  name = "${each.key} ${each.value[0]}"
  credentials {
    role_arn    = "arn:aws:iam::${each.value[0]}:role/lacework_role"
    external_id = each.value[1]
  }
}
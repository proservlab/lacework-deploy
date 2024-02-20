# provider "restapi" {
#     alias = "attacker"
#     uri                  = "https://api.dynu.com/v2"
#     write_returns_object = true
#     debug                = true

#     headers = {
#     "API-Key" = try(var.attacker_dynu_api_key, ""),
#     "Content-Type" = "application/json",
#     "accept" = "application/json"
#     }

#     create_method  = "POST"
#     update_method  = "PUT"
#     destroy_method = "DELETE"
# }

# provider "restapi" {
#     alias = "target"
#     uri                  = "https://api.dynu.com/v2"
#     write_returns_object = true
#     debug                = false

#     headers = {
#     "API-Key" = try(var.target_dynu_api_key, ""),
#     "Content-Type" = "application/json",
#     "accept" = "application/json"
#     }

#     create_method  = "POST"
#     update_method  = "PUT"
#     destroy_method = "DELETE"
# }
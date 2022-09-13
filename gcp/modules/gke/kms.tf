# resource "google_kms_key_ring" "keyring" {
#   name     = "${var.environment}-keyring"
#   location = "global"

#   lifecycle {
#     prevent_destroy = false
#   }
# }


# resource "google_kms_crypto_key" "key" {
#   name            = "${var.environment}-key"
#   key_ring        = google_kms_key_ring.keyring.id

#   lifecycle {
#     prevent_destroy = false
#   }
# }

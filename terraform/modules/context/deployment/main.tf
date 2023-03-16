resource "random_string" "this" {
    length            = 8
    special           = false
    upper             = false
    lower             = true
    numeric           = true
}
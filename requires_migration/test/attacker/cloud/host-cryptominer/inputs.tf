variable "region" {
    type = string
    default = "us-east-1"
}

variable "name" {
    type = string
    default = "miner"
}

variable "wallet" {
    type = string
}

variable "instances" {
    type = number
    default = 1
}
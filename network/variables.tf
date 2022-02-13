
variable "prefix" {
  type = string
}

variable "vpc_cidr_block" {
  type    = string
  default = "172.16.0.0/16"
}

variable "enable_private_subnets" {
  type    = bool
  default = true
}

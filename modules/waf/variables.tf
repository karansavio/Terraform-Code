#   name               = "tfIPSet"
#   ip_address_version = "IPV4"
#   scope              = "REGIONAL"
#   addresses          = ["192.0.7.0/24"]

variable "ipset_name" {
  type    = string
  default = "tfIPSet"

}

variable "ip_address_version" {
  type    = string
  default = "IPV4"

}

variable "scope" {
  type    = string
  default = "REGIONAL"

}

variable "ip_addresses" {
  type    = set(string)
  default = ["192.0.7.0/24"]

}

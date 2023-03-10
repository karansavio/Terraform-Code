variable "region" {
  type    = string
  default = "ap-southeast-2"

}

variable "cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}

variable "availability_zones" {
  type    = list(string)
  default = ["ap-southeast-2a", "ap-southeast-2b"]
}

variable "private_subnets" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "http_port" {
  type        = number
  default     = 80
}

variable "https_port" {
  type        = number
  default     = 443
}

variable "application_cidr_blocks" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
}




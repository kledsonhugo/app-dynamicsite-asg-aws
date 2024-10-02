# NETWORK VARS: DEFAULT VALUES

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "subnet_pub_az1a_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "subnet_pub_az1c_cidr" {
  type    = string
  default = "10.0.3.0/24"
}

variable "subnet_priv_az1a_cidr" {
  type    = string
  default = "10.0.2.0/24"
}

variable "subnet_priv_az1c_cidr" {
  type    = string
  default = "10.0.4.0/24"
}

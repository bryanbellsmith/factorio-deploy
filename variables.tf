variable "region" {
  default = "us-east-1"
}

variable "home_ip" {
}

variable "amis" {
  type = "map"
}

variable "ssh_key_name" {
  default = "Home"
}
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

variable "s3_bucket" {
  default = "greydevilfactorio"
}

variable "port" {
  default = "34197"
}

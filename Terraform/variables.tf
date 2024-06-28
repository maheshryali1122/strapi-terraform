variable "region" {
  type = string
  default = "us-west-2"
}
variable "privatekey" {
  type        = string
  sensitive   = true
}
variable "instance_type" {
  type = string
}
variable "number" {
  type = string
  default = "1.0"
}
variable "key_name" {
  type =string
}



variable "region" {
  type = string
  default = "us-west-2"
}
variable "docker_tag" {
  type = string
  default = "1.0"
}
variable "user" {
  type = string
  sensitive = true
}
variable "privatekey" {
  type        = string
  sensitive   = true
}
variable "instancetype" {
  type = string
}
variable "docker_username" {
  type = string
  sensitive = true
}
variable "docker_password" {
  type = string
  sensitive = true
}



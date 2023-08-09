variable "instance_id" {
  description = "[Spot] Instance ID (null if stopped)"
  type = string
  default = null
  required = false
}

variable "region" {
  description = "AWS region for resources"
  type = string
}

variable "home_disk_size" {
  description = "What should the size of the home disk be?"
  type = number
  default = 10
}

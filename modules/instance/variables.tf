variable "arch" {
  description = "Architecture of the instance"
  type = string
  validation {
    condition = contains(["x86_64", "aarch64"])
  }
}

variable "is_spot" {
  description = "Whether to request a spot instance or not"
  type = bool
}

variable "spot_price" {
  description = "Spot price (in cents??)"
  type = number
  required = false
}

variable "region" {
  description = "AWS region for resources"
}

variable "instance_type" {
  description = "Instance type for resource"
}

variable "root_disk_size" {
  description = "What should the size of the root disk be?"
  type = number
  default = 15
}

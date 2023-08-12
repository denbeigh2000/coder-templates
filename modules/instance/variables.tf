variable "arch" {
  description = "Architecture of the instance"
  type = string
  validation {
    condition = contains(["x86_64", "aarch64"], var.arch)
    error_message = "invalid architecture"
  }
}

variable "is_spot" {
  description = "Whether to request a spot instance or not"
  type = bool
}

variable "spot_price" {
  description = "Spot price (in cents??)"
  default = 0
  type = number
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

variable "flake_uri" {
  description = "NixOS configuration flake URI to apply"
  type = string
}

// This has to be in the top level for coder to be "aware" of it, apparently
variable "coder_agent" {
  description = "Coder agent from top-level"
}

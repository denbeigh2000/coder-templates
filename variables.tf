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

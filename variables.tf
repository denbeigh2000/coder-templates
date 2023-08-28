variable "arch" {
  description = "Architecture of the instance"
  type        = string
  validation {
    condition     = contains(["x86_64", "aarch64"], var.arch)
    error_message = "invalid architecture"
  }
}

variable "is_spot" {
  description = "Whether to request a spot instance or not"
  type        = bool
}

variable "default_agent_user" {
  default     = "denbeigh"
  description = "Default user to run the coder agent as. Overridable at workspace creation time."
  type        = string
}

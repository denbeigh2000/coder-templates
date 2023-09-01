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

variable "spot_price" {
  description = "Spot price"
  default     = ""
  type        = string
}

variable "region" {
  description = "AWS region for resources"
  type        = string
}

variable "availability_zone" {
  description = "AWS availability zone for resources"
  type        = string
}

variable "instance_type" {
  description = "Instance type for resource"
  type        = string
}

variable "root_disk_size" {
  description = "What should the size of the root disk be?"
  type        = number
  default     = 15
}

variable "flake_uri" {
  description = "NixOS configuration flake URI to apply"
  type        = string
}

// This has to be in the top level for coder to be "aware" of it, apparently
// type = any because we don't concern ourselves with this type anyway, we just
// pass it to other resources from the Coder provider.
variable "coder_agent" {
  description = "Coder agent from top-level"
  type        = any
}

variable "coder_agent_user" {
  description = "User to run the coder agent as. This should be created by your Nix config."
  type        = string
}

variable "iam_role_name" {
  description = "Name of AWS IAM role name to attach to the instance."
  type        = string
  default     = ""
}

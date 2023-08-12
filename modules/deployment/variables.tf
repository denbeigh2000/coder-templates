variable "arch" {
  description = "Architecture of the instance"
  type = string
  validation {
    condition = contains(["x86_64", "aarch64"], var.arch)
    error_message = "invalid architecture"
  }
}

variable "flake_uri" {
  description = "What flake should be run?"
}

variable "root_disk_size" {
  description = "What should the size of the root disk be?"
  type = number
  default = 15
}

variable "home_disk_size" {
  description = "What should the size of the home disk be?"
  type = number
  default = 10
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

# Last updated 2022-05-31
# aws ec2 describe-regions | jq -r '[.Regions[].RegionName] | sort'
variable "region" {
  description = "What region should your workspace live in?"
  default     = "us-west-2"
  validation {
    condition = contains([
      "ap-northeast-1",
      "ap-northeast-2",
      "ap-northeast-3",
      "ap-south-1",
      "ap-southeast-1",
      "ap-southeast-2",
      "ca-central-1",
      "eu-central-1",
      "eu-north-1",
      "eu-west-1",
      "eu-west-2",
      "eu-west-3",
      "sa-east-1",
      "us-east-1",
      "us-east-2",
      "us-west-1",
      "us-west-2"
    ], var.region)
    error_message = "Invalid region!"
  }
}

variable "instance_type" {
  description = "What instance type should your workspace use?"
  default     = "t3.micro"
  validation {
    condition = contains([
      "t3.micro",
      "t3.small",
      "t3.medium",
      "t3.large",
      "t3.xlarge",
      "t3.2xlarge",
    ], var.instance_type)
    error_message = "Invalid instance type!"
  }
}

// This has to be in the top level for coder to be "aware" of it, apparently
variable "coder_agent" {
  description = "Coder agent from top-level"
}

data "coder_parameter" "flake_uri" {
  name         = "flake_uri"
  display_name = "Flake URI"
  description  = "URI of the NixOS configuration flake to be installed on the system"
  type         = "string"
  mutable      = true
}

data "coder_parameter" "agent_user" {
  name         = "agent_user"
  display_name = "Username"
  description  = "User to login as. This user should be created by your NixOS config"
  type         = "string"
  default      = var.default_agent_user
  mutable      = true
}

data "coder_parameter" "root_disk_size" {
  name         = "root_disk_size"
  display_name = "Root disk size"
  description  = "Size of the root disk of the instance"
  type         = "number"
  mutable      = true
  validation {
    min       = 1
    monotonic = "increasing"
  }

  default = 15
}

data "coder_parameter" "home_disk_size" {
  name         = "home_disk_size"
  display_name = "Home disk size"
  description  = "Size of the home disk of the instance"
  type         = "number"
  mutable      = true
  validation {
    min       = 1
    monotonic = "increasing"
  }

  default = 10
}

data "coder_parameter" "instance_type" {
  name         = "instance_type"
  display_name = "Instance type"
  description  = "Instance type to deploy"
  default      = "t3.micro"
  type         = "string"
  mutable      = true

  // NOTE: Too many types.
  // dynamic "option" {
  //   for_each = toset(local._local-types)
  //   content {
  //     name = option.key
  //     value = option.key
  //   }
  // }
}

data "coder_parameter" "region" {
  name         = "region"
  display_name = "Region"
  default      = "us-west-2"
  type         = "string"
  description  = "Region to deploy instance to"
  mutable      = false

  dynamic "option" {
    for_each = toset(local.regions)
    content {
      name  = option.key
      value = option.key
    }
  }
}

data "coder_parameter" "iam_role_name" {
  name         = "iam_role_name"
  display_name = "IAM Role Name"
  description  = "If given, the deployed instance will be able to assume this IAM role. The IAM role must have a sufficiently permissive assume_role_policy to allow EC2 instances to assume the role."
  default      = ""
  type         = "string"
  mutable      = true
}

data "coder_parameter" "spot_price" {
  count        = var.is_spot ? 1 : 0
  name         = "spot_price"
  display_name = "Spot price"
  description  = "Maximum spot price. Leave empty for unlimited"
  default      = ""
  type         = "string"
  mutable      = true
}

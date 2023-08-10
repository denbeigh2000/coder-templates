terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "0.4.9"
    }
  }
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
      "t3.xlarge",
      "t3.2xlarge",
      "t3a.micro",
      "t3a.xlarge",
      "t3a.2xlarge",
      "c5.xlarge",
      "c1.xlarge",
    ], var.instance_type)
    error_message = "Invalid instance type!"
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
data "coder_workspace" "me" {
}

module "box" {
  count = data.coder_workspace.me.start_count
  source         = "./modules/instance"
  arch           = "x86_64"
  is_spot        = true
  region         = var.region
  flake_uri      = var.flake_uri
  instance_type  = var.instance_type
  root_disk_size = var.root_disk_size
}

module "common" {
  source         = "./modules/common"

  region         = var.region
  instance_id    = data.coder_workspace.me.start_count == 0 ? null : module.box[0].instance_id
  home_disk_size = var.home_disk_size
}

resource "coder_metadata" "workspace_info" {
  count       = data.coder_workspace.me.start_count
  resource_id = module.box[0].instance_id
  item {
    key   = "region"
    value = var.region
  }
  item {
    key   = "instance type"
    // TODO: Expose this through instance?
    value = var.instance_type
  }
  // TODO: Expose this again?
  // item {
  //   key   = "root disk"
  //   value = "${aws_spot_instance.box[0].root_block_device[0].volume_size} GiB"
  // }
}

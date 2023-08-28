terraform {
  required_version = ">= 1.5"
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "0.11.1"
    }

    aws = {
      source  = "aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = data.coder_parameter.region.value
}

data "coder_workspace" "me" {
}

locals {
  arch_mapping = {
    x86_64  = "amd64"
    aarch64 = "arm64"
  }
}

resource "coder_agent" "box" {
  arch = local.arch_mapping[var.arch]
  auth = "aws-instance-identity"
  os   = "linux"
}

resource "coder_agent_instance" "box" {
  count       = data.coder_workspace.me.start_count
  agent_id    = coder_agent.box.id
  instance_id = module.box[0].instance_id
}

module "box" {
  count  = data.coder_workspace.me.start_count
  source = "./modules/instance"

  coder_agent      = coder_agent.box
  arch             = var.arch
  is_spot          = var.is_spot
  region           = data.coder_parameter.region.value
  flake_uri        = data.coder_parameter.flake_uri.value
  instance_type    = data.coder_parameter.instance_type.value
  root_disk_size   = data.coder_parameter.root_disk_size.value
  coder_agent_user = data.coder_parameter.agent_user.value
}

module "common" {
  source = "./modules/common"

  region         = data.coder_parameter.region.value
  instance_id    = data.coder_workspace.me.start_count == 0 ? null : module.box[0].instance_id
  home_disk_size = data.coder_parameter.home_disk_size.value
}

resource "coder_metadata" "workspace_info" {
  count       = data.coder_workspace.me.start_count
  resource_id = module.box[0].instance_id
  item {
    key   = "region"
    value = data.coder_parameter.region.value
  }
  item {
    key = "instance type"
    // TODO: Expose this through instance?
    value = data.coder_parameter.instance_type.value
  }
  item {
    key = "root disk"
    // TODO: Expose this through instance?
    value = "${data.coder_parameter.root_disk_size.value} GiB"
  }
}


terraform {
  required_version = ">= 1.2"
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

  startup_script          = <<EOT
#!/usr/bin/env bash

sudo nixos-rebuild switch --flake '${data.coder_parameter.flake_uri.value}'
hash -r
EOT
  startup_script_behavior = "blocking"
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
  home_disk_size   = data.coder_parameter.home_disk_size.value
  coder_agent_user = data.coder_parameter.agent_user.value
  iam_role_name    = data.coder_parameter.iam_role_name.value != "" ? data.coder_parameter.iam_role_name.value : null
  spot_price       = var.is_spot ? data.coder_parameter.spot_price[0].value : 0
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

# NOTE: If we don't explicitly have this, Coder appears to be unaware of the
# resource at all.
resource "null_resource" "ensure_agent" {
  depends_on = [coder_agent.box]
}

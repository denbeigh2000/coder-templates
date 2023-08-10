terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "0.4.9"
    }
  }
}

locals {
  # User data is used to stop/start AWS instances. See:
  # https://github.com/hashicorp/terraform-provider-aws/issues/22

  user_data_start = <<EOT
#!/usr/bin/env bash
exec > $HOME/provision.log
exec 2> $HOME/provision.err

# this doesn't seem to be sourced beforehand
source /etc/profile

nixos-rebuild switch --flake '${var.flake_uri}'
hash -r
export CODER_AGENT_TOKEN=${coder_agent.box.token}
sudo --preserve-env=CODER_AGENT_TOKEN -u denbeigh bash -c '${coder_agent.box.init_script}'
EOT

  user_data_end = <<EOT
#!/usr/bin/env bash
sudo shutdown -h now
EOT

  is_on       = data.coder_workspace.me.start_count != 0
  instance_id = var.is_spot ? module.instance_spot[0].instance_id : module.instance_nonspot[0].instance_id

  archs = {
    aarch64 = "arm64"
    x86_64 = "amd64"
  }
}

data "coder_workspace" "me" {
}

resource "coder_agent" "box" {
  arch = local.archs[var.arch]
  auth = "aws-instance-identity"
  os   = "linux"
}

resource "coder_agent_instance" "box" {
  count = local.is_on ? 1 : 0
  agent_id = coder_agent.box.id
  instance_id = local.instance_id
}

module "instance_spot" {
  count = var.is_spot ? data.coder_workspace.me.start_count : 0
  source = "../instance-spot"

  region = var.region
  arch = var.arch
  root_disk_size = var.root_disk_size
  instance_type = var.instance_type
  user_data_start = local.user_data_start
  user_data_end = local.user_data_end
  spot_price = var.spot_price
}

module "instance_nonspot" {
  count = (!var.is_spot) ? data.coder_workspace.me.start_count : 0
  source = "../instance-nonspot"

  region = var.region
  arch = var.arch
  root_disk_size = var.root_disk_size
  instance_type = var.instance_type
  user_data_start = local.user_data_start
  user_data_end = local.user_data_end
}

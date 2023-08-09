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
}

provider "aws" {
  region = var.region
}

data "coder_workspace" "me" {
}

resource "coder_agent" "box" {
  arch = var.arch
  auth = "aws-instance-identity"
  os   = "linux"
}

resource "coder_agent_instance" "box" {
  count = var.instance_id != null ? 1 : 0
  agent_id = coder_agent.box.id
  instance_id = aws_spot_instance_request.box[0].spot_instance_id
}

module "instance_spot" {
  count = var.is_spot ? data.coder_workspace.me.start_count : 0
  source = "../instance-spot"

  root_disk_size = var.root_disk_size
  instance_type = var.instance_type
  root_disk_size = var.root_disk_size
  user_data_start = var.user_data_start
  user_data_end = var.user_data_end
  spot_prce = var.spot_prce
}

module "instance_nonspot" {
  count = (!var.is_spot) ? data.coder_workspace.me.start_count : 0
  source = "../instance-nonspot"

  root_disk_size = var.root_disk_size
  instance_type = var.instance_type
  root_disk_size = var.root_disk_size
  user_data_start = var.user_data_start
  user_data_end = var.user_data_end
}

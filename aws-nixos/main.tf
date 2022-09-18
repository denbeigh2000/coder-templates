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
      "t3.small",
      "t3.medium",
      "t3.large",
      "t3.xlarge",
      "t3.2xlarge",
    ], var.instance_type)
    error_message = "Invalid instance type!"
  }
}

variable "flake_uri" {
  description = "What flake should be run?"
}

locals {
  # rg -F 'x86_64-linux.hvm-ebs' nixos/modules/virtualisation/amazon-ec2-amis.nix \
  #   | grep 22.05 \
  #   | sed 's/ = /./' \
  #   | cut -d. -f3,6 \
  #   | sed 's|\(.*\)\."\(.*\)";$|\1 = "\2",|' \
  #   | sort
  images = {
    af-south-1 = "ami-0d3a6166c1ea4d7b4",
    ap-east-1 = "ami-06445325c360470d8",
    ap-northeast-1 = "ami-009c422293bcf3721",
    ap-northeast-2 = "ami-0bfc0397525a67ed8",
    ap-northeast-3 = "ami-0a1fb4d4e08a6065e",
    ap-south-1 = "ami-07ad258dcc69239d2",
    ap-southeast-1 = "ami-0f59f7f33cba8b1a4",
    ap-southeast-2 = "ami-0d1e49fe30aec165d",
    ap-southeast-3 = "ami-0f5cb24a1e3fc62dd",
    ca-central-1 = "ami-0551a595ba7916462",
    eu-central-1 = "ami-0702eee2e75d541d1",
    eu-north-1 = "ami-0fc6838942cb7d9cb",
    eu-south-1 = "ami-0df9463b8965cdb80",
    eu-west-1 = "ami-00badba5cfa0a0c0d",
    eu-west-2 = "ami-08f3c1eb533a42ac1",
    eu-west-3 = "ami-04b50c79dc4009c97",
    me-south-1 = "ami-05c52087afab7024d",
    sa-east-1 = "ami-0732aa0f0c28f281b",
    us-east-1 = "ami-0223db08811f6fb2d",
    us-east-2 = "ami-0a743534fa3e51b41",
    us-west-1 = "ami-0d72ab697beab5ea5",
    us-west-2 = "ami-034946f0c47088751",
  }

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
  arch = "amd64"
  auth = "aws-instance-identity"
  os   = "linux"
}

resource "coder_agent_instance" "box" {
  count = data.coder_workspace.me.start_count
  agent_id = coder_agent.box.id
  instance_id = aws_instance.box[0].id
}

resource "aws_ebs_volume" "home_disk" {
  availability_zone = "${var.region}a"
  size = 10
  type = "gp3"
}

resource "aws_volume_attachment" "box_home_disk" {
  count = data.coder_workspace.me.start_count
  # NOTE: This is tied to a volume mount in NixOS configs for Coder workspaces.
  device_name = "/dev/xvdb"
  volume_id = aws_ebs_volume.home_disk.id
  instance_id = aws_instance.box[0].spot_instance_id
}

resource "aws_instance" "box" {
  count = data.coder_workspace.me.start_count
  ami               = local.images[var.region]
  availability_zone = "${var.region}a"
  instance_type     = var.instance_type

  root_block_device {
    volume_size = 15
    volume_type = "gp3"
  }

  user_data = data.coder_workspace.me.transition == "start" ? local.user_data_start : local.user_data_end
  tags = {
    Name = "coder-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}"
  }
}

resource "coder_metadata" "workspace_info" {
  count = data.coder_workspace.me.start_count
  resource_id = aws_spot_instance.box[0].id
  item {
    key   = "region"
    value = var.region
  }
  item {
    key   = "instance type"
    value = aws_spot_instance.box[0].instance_type
  }
  item {
    key   = "root disk"
    value = "${aws_spot_instance.box[0].root_block_device[0].volume_size} GiB"
  }
  item {
    key = "home disk"
    value = "${aws_ebs_volume.home_disk.size} GiB"
  }
}

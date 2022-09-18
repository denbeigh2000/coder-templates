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
  default     = "t4g.micro"
  validation {
    condition = contains([
      "t4g.micro",
      "t4g.small",
      "t4g.medium",
      "t4g.large",
      "t4g.xlarge",
      "t4g.2xlarge",
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

locals {
  # rg -F aarch64-linux.hvm-ebs' nixos/modules/virtualisation/amazon-ec2-amis.nix \
  #   | grep 22.05 \
  #   | sed 's/ = /./' \
  #   | cut -d. -f3,6 \
  #   | sed 's|\(.*\)\."\(.*\)";$|\1 = "\2",|' \
  #   | sort
  images = {
    af-south-1 = "ami-0a9b83913abd61694",
    ap-east-1 = "ami-03966ad4547f532b7",
    ap-northeast-1 = "ami-0eb7e152c8d5aae7d",
    ap-northeast-2 = "ami-08369e00c5528762b",
    ap-northeast-3 = "ami-0fa14b8d48cdd57c3",
    ap-south-1 = "ami-0f2ca3b542ff0913b",
    ap-southeast-1 = "ami-087def0511ef2687d",
    ap-southeast-2 = "ami-0aa90985199011f04",
    ap-southeast-3 = "ami-0c86c52790deefa23",
    ca-central-1 = "ami-06e932cc9c20403e4",
    eu-central-1 = "ami-07680df1026a9b54c",
    eu-north-1 = "ami-0cbe9f2725e4de706",
    eu-south-1 = "ami-01a83c3892925765f",
    eu-west-1 = "ami-08114069426233360",
    eu-west-2 = "ami-049024d086d039b54",
    eu-west-3 = "ami-0c0ebe20ebfc635a1",
    me-south-1 = "ami-0d662fcaac553e945",
    sa-east-1 = "ami-0888c8f703e00fdb8",
    us-east-1 = "ami-03536a13324333073",
    us-east-2 = "ami-067611519fa817aaa",
    us-west-1 = "ami-0f96be48071c13ab2",
    us-west-2 = "ami-084bc5d777585adfb",
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
  arch = "arm64"
  auth = "aws-instance-identity"
  os   = "linux"
}

resource "coder_agent_instance" "box" {
  count = data.coder_workspace.me.start_count
  agent_id = coder_agent.box.id
  instance_id = aws_spot_instance_request.box[0].spot_instance_id
}

resource "aws_ebs_volume" "home_disk" {
  availability_zone = "${var.region}a"
  size = var.home_disk_size
  type = "gp3"

  tags = {
    App = "coder"
    CoderPurpose = "home-disk-volume"
    CoderUser = data.coder_workspace.me.owner
  }
}

resource "aws_volume_attachment" "box_home_disk" {
  count = data.coder_workspace.me.start_count
  # NOTE: This is tied to a volume mount in NixOS configs for Coder workspaces.
  device_name = "/dev/xvdb"
  volume_id = aws_ebs_volume.home_disk.id
  instance_id = aws_spot_instance_request.box[0].spot_instance_id
}

resource "aws_spot_instance_request" "box" {
  count = data.coder_workspace.me.start_count
  ami               = local.images[var.region]
  availability_zone = "${var.region}a"
  instance_type     = var.instance_type

  root_block_device {
    volume_size = var.root_disk_size
    volume_type = "gp3"
  }

  wait_for_fulfillment = true
  instance_interruption_behavior = "stop"

  user_data = local.user_data_start
  tags = {
    Name = "coder-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}"
    App = "coder"
    CoderPurpose = "workspace-spot-instance"
    CoderUser = data.coder_workspace.me.owner
  }
}

data "aws_ec2_spot_price" "box" {
  instance_type     = "${var.instance_type}"
  availability_zone = "${var.region}a"

  filter {
    name   = "product-description"
    values = ["Linux/UNIX"]
  }
}

resource "coder_metadata" "workspace_info" {
  count = data.coder_workspace.me.start_count
  resource_id = aws_spot_instance_request.box[0].id
  item {
    key = "cost"
    value = "${data.aws_ec2_spot_price.box.spot_price}/hr"
  }
  item {
    key   = "region"
    value = var.region
  }
  item {
    key   = "instance type"
    value = aws_spot_instance_request.box[0].instance_type
  }
  item {
    key   = "disk size (root)"
    value = "${aws_spot_instance_request.box[0].root_block_device[0].volume_size} GiB"
  }
}

resource "coder_metadata" "home_disk_info" {
  resource_id = aws_ebs_volume.home_disk.id

  item {
    key   = "disk size (home)"
    value = "${aws_ebs_volume.home_disk.size} GiB"
  }
}

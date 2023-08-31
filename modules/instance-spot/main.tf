terraform {
  required_version = ">= 1.2"
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "~> 0.11"
    }

    aws = {
      source  = "aws"
      version = "~> 5.0"
    }
  }
}

data "coder_workspace" "me" {
}

module "data" {
  source = "../data"
}

locals {
  default_name = "coder-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}"
}

resource "aws_spot_instance_request" "box" {
  count             = data.coder_workspace.me.start_count
  ami               = module.data.images[var.arch][var.region]
  availability_zone = "${var.region}a"
  instance_type     = var.instance_type

  wait_for_fulfillment           = true
  instance_interruption_behavior = "stop"

  root_block_device {
    volume_size = var.root_disk_size
    volume_type = "gp3"
  }

  user_data = data.coder_workspace.me.transition == "start" ? var.user_data_start : var.user_data_end
  tags = {
    Name         = var.instance_name != "" ? var.instance_name : local.default_name
    App          = "coder"
    CoderPurpose = "workspace-spot-instance"
    CoderUser    = data.coder_workspace.me.owner
  }

  iam_instance_profile = var.instance_profile_name != "" ? var.instance_profile_name : null
}

resource "coder_metadata" "workspace_info" {
  count       = data.coder_workspace.me.start_count
  resource_id = aws_spot_instance_request.box[0].id
  item {
    key   = "cost"
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

data "aws_ec2_spot_price" "box" {
  instance_type     = var.instance_type
  availability_zone = "${var.region}a"

  filter {
    name   = "product-description"
    values = ["Linux/UNIX"]
  }
}

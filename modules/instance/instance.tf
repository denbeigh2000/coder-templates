module "data" {
  source = "../data"
}

locals {
  default_name = "coder-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}"
}

resource "aws_instance" "box" {
  count             = data.coder_workspace.me.start_count
  ami               = module.data.images[var.arch][var.region]
  availability_zone = var.availability_zone
  instance_type     = var.instance_type

  root_block_device {
    volume_size = var.root_disk_size
    volume_type = "gp3"
  }

  dynamic "instance_market_options" {
    for_each = var.is_spot ? toset(["."]) : toset([])
    content {
      market_type = "spot"
      spot_options {
        max_price = var.spot_price
      }
    }
  }

  user_data = data.coder_workspace.me.transition == "start" ? local.user_data_start : local.user_data_end
  tags = {
    Name         = "coder-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}"
    App          = "coder"
    CoderPurpose = "workspace-instance"
    CoderUser    = data.coder_workspace.me.owner
  }

  iam_instance_profile = var.iam_role_name != null ? module.iam[0].instance_profile_name : null
}

resource "coder_metadata" "workspace_info" {
  count       = data.coder_workspace.me.start_count
  resource_id = aws_instance.box[0].id
  item {
    key   = "region"
    value = var.region
  }
  item {
    key   = "instance type"
    value = aws_instance.box[0].instance_type
  }
  item {
    key   = "disk size (root)"
    value = "${aws_instance.box[0].root_block_device[0].volume_size} GiB"
  }
}

resource "coder_metadata" "spot_workspace_info" {
  count       = var.is_spot ? data.coder_workspace.me.start_count : 0
  resource_id = aws_instance.box[0].id
  item {
    key   = "cost"
    value = "${data.aws_ec2_spot_price.box[0].spot_price}/hr"
  }
}

data "aws_ec2_spot_price" "box" {
  count             = var.is_spot ? data.coder_workspace.me.start_count : 0
  instance_type     = var.instance_type
  availability_zone = "${var.region}a"

  filter {
    name   = "product-description"
    values = ["Linux/UNIX"]
  }
}


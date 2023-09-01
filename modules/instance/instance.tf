module "data" {
  source = "../data"
}

locals {
  default_name = "coder-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}"
}

resource "aws_instance" "box" {
  count             = data.coder_workspace.me.start_count
  ami               = module.data.images[var.arch][var.region]
  availability_zone = aws_ebs_volume.home_disk.availability_zone
  instance_type     = var.instance_type

  root_block_device {
    volume_size = var.root_disk_size
    volume_type = "gp3"
  }

  dynamic "instance_market_options" {
    # HACK: Create a set of size 1 to conditionally request a spot instance.
    for_each = var.is_spot ? toset(["."]) : toset([])
    content {
      market_type = "spot"
      spot_options {
        max_price = var.spot_price != "" ? var.spot_price : null
        # Using the default of one-time means we can't issue a stop command to
        # the instance.
        spot_instance_type = "persistent"

        # https://github.com/aws/aws-sdk-ruby/issues/1798#issuecomment-396297308
        # We cannot use the default of "terminate" for interruptions for
        # persistent spot requests, and need to explicitly specify stop
        instance_interruption_behavior = "stop"
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
  availability_zone = aws_ebs_volume.home_disk.availability_zone

  filter {
    name   = "product-description"
    values = ["Linux/UNIX"]
  }
}

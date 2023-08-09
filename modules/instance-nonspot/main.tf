provider "aws" {
  region = var.region
}

data "coder_workspace" "me" {
}

locals {
  default_name = "coder-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}"
}

resource "aws_instance" "box" {
  count = data.coder_workspace.me.start_count
  ami               = local.images[var.region]
  availability_zone = "${var.region}a"
  instance_type     = var.instance_type

  root_block_device {
    volume_size = var.root_disk_size
    volume_type = "gp3"
  }

  user_data = data.coder_workspace.me.transition == "start" ? local.user_data_start : local.user_data_end
  tags = {
    Name = "coder-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}"
    App = "coder"
    CoderPurpose = "workspace-instance"
    CoderUser = data.coder_workspace.me.owner
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
}


data "coder_workspace" "me" {
}

provider "aws" {
  region = var.region
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
  instance_id = var.instance_id
}

resource "coder_metadata" "home_disk_info" {
  resource_id = aws_ebs_volume.home_disk.id

  item {
    key   = "disk size (home)"
    value = "${aws_ebs_volume.home_disk.size} GiB"
  }
}

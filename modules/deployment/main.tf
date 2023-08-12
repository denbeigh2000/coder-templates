data "coder_workspace" "me" {
}

module "box" {
  count = data.coder_workspace.me.start_count
  source         = "../instance"

  coder_agent    = var.coder_agent
  arch           = var.arch
  is_spot        = var.is_spot
  region         = var.region
  flake_uri      = var.flake_uri
  instance_type  = var.instance_type
  root_disk_size = var.root_disk_size
}

module "common" {
  source         = "../common"

  region         = var.region
  instance_id    = data.coder_workspace.me.start_count == 0 ? null : module.box[0].instance_id
  home_disk_size = var.home_disk_size
}

resource "coder_metadata" "workspace_info" {
  count       = data.coder_workspace.me.start_count
  resource_id = module.box[0].instance_id
  item {
    key   = "region"
    value = var.region
  }
  item {
    key   = "instance type"
    // TODO: Expose this through instance?
    value = var.instance_type
  }
  // TODO: Expose this again?
  // item {
  //   key   = "root disk"
  //   value = "${aws_spot_instance.box[0].root_block_device[0].volume_size} GiB"
  // }
}


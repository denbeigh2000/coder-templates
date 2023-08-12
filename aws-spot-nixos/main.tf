terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "0.6.10"
    }
    aws = {
      source = "aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

module "deployment" {
  source         = "./modules/deployment"

  arch           = "x86_64"
  flake_uri      = var.flake_uri
  root_disk_size = var.root_disk_size
  home_disk_size = var.home_disk_size
  is_spot        = true
  spot_price     = var.spot_price
  region         = var.region
  instance_type  = var.instance_type

  coder_agent    = coder_agent.box
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
  instance_id = module.deployment.instance_id
}

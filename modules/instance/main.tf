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

locals {
  bootstrap_module_path    = "/tmp/bootstrap.nix"
  encoded_bootstrap_module = filebase64("${path.module}/bootstrap.nix")
  bootstrap_config         = <<EOT
{
  imports = [
    (import ${local.bootstrap_module_path} { user = "${var.coder_agent_user}"; })
  ];
}
EOT
  encoded_bootstrap_config = base64encode(local.bootstrap_config)

  # User data is used to stop/start AWS instances. See:
  # https://github.com/hashicorp/terraform-provider-aws/issues/22
  user_data_start = <<EOT
#!/usr/bin/env bash
exec > /tmp/bootstrap.log
exec 2> /tmp/bootstrap.err

# this doesn't seem to be sourced beforehand
source /etc/profile

echo '${local.encoded_bootstrap_module}' | base64 -d > ${local.bootstrap_module_path}
echo '${local.encoded_bootstrap_config}' | base64 -d > /etc/nixos/configuration.nix
nixos-rebuild --fast test
hash -r

export CODER_AGENT_TOKEN=${var.coder_agent.token}
sudo --preserve-env=CODER_AGENT_TOKEN -u ${var.coder_agent_user} bash -c '${var.coder_agent.init_script}'
EOT

  user_data_end = <<EOT
#!/usr/bin/env bash
sudo shutdown -h now
EOT

  is_on = data.coder_workspace.me.start_count != 0
}

data "coder_workspace" "me" {
}

module "iam" {
  count  = var.iam_role_name != null ? data.coder_workspace.me.start_count : 0
  source = "../iam"

  iam_role_name = var.iam_role_name
}

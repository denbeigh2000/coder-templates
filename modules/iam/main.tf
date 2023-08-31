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

resource "aws_iam_instance_profile" "instance_profile" {
  name_prefix = "coder-managed-"
  role        = data.aws_iam_role.given_role.name
}

data "aws_iam_role" "given_role" {
  name = var.iam_role_name
}

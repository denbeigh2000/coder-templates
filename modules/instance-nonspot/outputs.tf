locals {
  is_on       = data.coder_workspace.me.start_count != 0
}

output "instance_id" {
  value = local.is_on ? aws_instance.box[0].id : null
}

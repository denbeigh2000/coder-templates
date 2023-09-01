output "instance_id" {
  value = local.is_on ? aws_instance.box[0].id : null
}

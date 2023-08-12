output "instance_id" {
  value = local.is_on ? local.instance_id : null
}

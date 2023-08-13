output "instance_id" {
  value = data.coder_workspace.me.start_count != 0 ? module.box[0].instance_id : null
}

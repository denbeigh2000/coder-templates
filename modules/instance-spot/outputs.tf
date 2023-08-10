output "instance_id" {
  value = aws_spot_instance_request.box[0].spot_instance_id
}

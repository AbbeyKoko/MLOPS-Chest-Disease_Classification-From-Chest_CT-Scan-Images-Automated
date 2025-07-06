output "mlops_private_ip" {
  value = aws_instance.mlops_ec2.private_ip
}

output "mlops_instance_id" {
  value = aws_instance.mlops_ec2.id
}
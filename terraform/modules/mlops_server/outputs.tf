output "mlops_private_ip" {
  value = aws_instance.mlops_ec2.private_ip
}

output "mlops_public_ip" {
  value = aws_instance.mlops_ec2.public_ip
}
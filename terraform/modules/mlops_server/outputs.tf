output "mlops_elastic_ip" {
  value = aws_eip.mlops_eip.public_ip
}

output "mlops_private_ip" {
  value = aws_instance.mlops_ec2.private_ip
}

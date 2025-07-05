output "mlops_elastic_ip" {
  value = aws_eip.mlops_eip.public_ip
}


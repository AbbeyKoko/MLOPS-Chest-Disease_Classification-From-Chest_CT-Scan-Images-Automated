output "key_name" {
  value = aws_key_pair.jenkins_key_pair.key_name
}

output "private_key_file" {
  description = "Path to the private key file"
  value = local_file.private_key_pem.filename
}
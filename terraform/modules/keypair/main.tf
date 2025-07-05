resource "tls_private_key" "jenkins_key" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "aws_key_pair" "jenkins_key_pair" {
  key_name = var.key_name
  public_key = tls_private_key.jenkins_key.public_key_openssh
}

resource "local_file" "private_key_pem" {
  content = tls_private_key.jenkins_key.private_key_pem
  filename = "${path.module}/${var.key_name}.pem"
  file_permission = "0600"
  directory_permission = "0700"
}
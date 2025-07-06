output "jenkins_private_ip" {
  value = aws_instance.jenkins_ec2.private_ip
}

output "jenkins_public_ip" {
  value = aws_instance.jenkins_ec2.public_ip
}

output "JENKINS_URL" {
  value = "http://${aws_instance.jenkins_ec2.public_ip}:${var.JENKINS_URL_PORT}"
}

output "JENKINS_PIPELINE" {
  value = var.JENKINS_PIPELINE
}

output "JENKINS_USER" {
  value = var.JENKINS_USER
}

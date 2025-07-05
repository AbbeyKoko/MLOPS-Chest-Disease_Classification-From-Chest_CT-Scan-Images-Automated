output "AWS_ACCOUNT_ID" {
  value = data.aws_caller_identity.current.account_id
  sensitive = true
}

output "AWS_ACCESS_KEY_ID" {
  value = module.terraform_user.access_key_id
  sensitive = true
}

output "AWS_SECRET_ACCESS_KEY" {
  value = module.terraform_user.secret_access_key
  sensitive = true
}

output "AWS_REGION" {
  value = var.region
}

output "IMAGE_TAG" {
  value = var.image_tag
}

output "ECR_REPOSITORY" {
  value = var.ecr_repo
}

output "key_pair_name" {
  value = module.keypair.key_name
}

output "private_key_path" {
  value = module.keypair.private_key_file
  sensitive = true
}

output "jenkins_elastic_ip" {
  value = module.jenkins_server.jenkins_elastic_ip
  sensitive = true
}

output "mlops_elastic_ip" {
  value = module.mlops_server.mlops_elastic_ip
  sensitive = true
}

output "JENKINS_USER" {
  value = module.jenkins_server.JENKINS_USER
}

output "JENKINS_PASSWORD" {
  value = var.JENKINS_PASSWORD
  sensitive = true
}

output "JENKINS_URL" {
  value = module.jenkins_server.JENKINS_URL
  sensitive = true
}

output "JENKINS_PIPELINE" {
  value = module.jenkins_server.JENKINS_PIPELINE
}

output "GITHUB_REPO" {
  value =  var.GITHUB_REPO
  sensitive = true
}

output "GITHUB_TOKEN" {
  value = var.GITHUB_TOKEN
  sensitive = true
}
variable "instance_type" {
  type = string
}

variable "region" {
  type = string
}
variable "availability_zone" {
  type = string
}

variable "profile" {
  type = string
  description = "Profile account to use"
}

variable "key_name" {
  description = "Name of the EC2 key pair to use for SSH"
  type        = string
}

variable "private_key_file" {
  description = "Path to the private key file"
  type        = string
}

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "JENKINS_USER" {
  type = string
}

variable "JENKINS_URL_PORT" {
  type = string
  default = "8080"
}

variable "JENKINS_PIPELINE" {
  type = string
  default = "terraform-mlops-pipeline"
}

variable "GITHUB_REPO" {
  type = string
}

variable "JENKINS_PASSWORD" {
  type = string
  sensitive = true
}
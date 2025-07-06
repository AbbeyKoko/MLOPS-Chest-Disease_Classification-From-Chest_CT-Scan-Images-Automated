variable "region" {
  type = string
  default = "eu-north-1"
}
variable "availability_zone" {
  type = string
  default = "eu-north-1a"
}

variable "instance_type" {
  type = string
  default = "t3.micro"
  description = "The type of instance to create"
}

variable "profile" {
  type = string
  description = "Profile account to use"
}

variable "image_tag" {
  type = string
  default = "latest"
}

variable "ecr_repo" {
  type = string
}

variable "ecr_repo_base" {
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

variable "GITHUB_TOKEN" {
  type = string
  sensitive = true
}

variable "JENKINS_USER" {
  type = string
}

variable "JENKINS_PASSWORD" {
  type = string
  sensitive = true
}

variable "iam_user_name" {
  type = string
}

variable "iam_group_name" {
  type = string
}

variable "iam_policy_name" {
  type = string
}

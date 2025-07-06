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

variable "image_tag" {
  type = string
  default = "latest"
}

variable "ecr_repo" {
  type = string
}

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
}

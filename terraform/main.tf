provider "aws" {
  region = var.region
  profile = var.profile
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}
module "terraform_user" {
  source      = "./modules/iam-terraform-user"
  user_name   = var.iam_user_name
  group_name  = var.iam_group_name
  policy_name = var.iam_policy_name
}

module "keypair" {
  source = "./modules/keypair"
  key_name = "jenkins-runtime-key"
}

data "aws_caller_identity" "current" {
}


module "jenkins_server" {
  source = "./modules/jenkins_server"
  instance_type = var.instance_type
  region = var.region
  key_name = module.keypair.key_name
  profile = var.profile
  aws_account_id = data.aws_caller_identity.current.account_id
  private_key_file = module.keypair.private_key_file
  JENKINS_USER = var.JENKINS_USER
  JENKINS_PASSWORD = var.JENKINS_PASSWORD
  GITHUB_REPO = var.GITHUB_REPO
}

module "mlops_server" {
  source = "./modules/mlops_server"
  instance_type = var.instance_type
  region = var.region
  key_name = module.keypair.key_name
  profile = var.profile
  ecr_repo = var.ecr_repo
  aws_account_id = data.aws_caller_identity.current.account_id
}

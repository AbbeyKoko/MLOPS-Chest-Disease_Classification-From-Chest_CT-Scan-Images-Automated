# locals {
#   jenkins_bootstrap = templatefile("${path.module}/scripts/jenkins-bootstrap.sh.tpl",
#     {
#       AWS_ACCOUNT_ID = var.aws_account_id
#       AWS_REGION = var.region
#       JENKINS_URL = "http://${aws_eip.jenkins_eip.public_ip}:${var.JENKINS_URL_PORT}"
#       JENKINS_USER = var.JENKINS_USER
#       JENKINS_PASSWORD = var.JENKINS_PASSWORD
#       JENKINS_PIPELINE = var.JENKINS_PIPELINE
#       GITHUB_REPO = var.GITHUB_REPO
#     }
#   )
# }

resource "aws_security_group" "jenkins_sg" {
  name = "jenkins-sg"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
}

resource "aws_iam_role" "ec2_role" {
  name = "jenkins-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_attach" {
  role = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}


resource "aws_iam_instance_profile" "ec2_profile" {
  name = "jenkins-instance-profile"
  role = aws_iam_role.ec2_role.name
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners = ["099720109477"]

  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}


resource "aws_instance" "jenkins_ec2" {
  ami = data.aws_ami.ubuntu.id  
  instance_type = var.instance_type
  key_name = var.key_name
  security_groups = [aws_security_group.jenkins_sg.name]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = true


  tags = {
    Name = "Jenkins-Server"
  }
}

resource "aws_eip" "jenkins_eip" {
  domain = "vpc"
  # depends_on = [ aws_instance.jenkins_ec2 ]
}

resource "aws_eip_association" "jenkins_eip_association" {
  instance_id = aws_instance.jenkins_ec2.id
  allocation_id = aws_eip.jenkins_eip.id
}

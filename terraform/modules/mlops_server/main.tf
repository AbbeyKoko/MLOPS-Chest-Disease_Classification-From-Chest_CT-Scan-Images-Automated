resource "aws_ecr_repository" "ecr" {
  name = var.ecr_repo
  image_tag_mutability = "MUTABLE"

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name =  var.ecr_repo
    Environment = "Development"
  }
}

resource "aws_security_group" "mlops_sg" {
  name = "mlops-sg"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  ingress {
    from_port = 8081
    to_port = 8081
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
  name = "mlops-ec2-role"

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
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}


resource "aws_iam_instance_profile" "ec2_profile" {
  name = "mlops-instance-profile"
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

data "aws_subnet" "default_subnet" {
  default_for_az = true
  availability_zone = var.availability_zone
}


resource "aws_instance" "mlops_ec2" {
  ami = data.aws_ami.ubuntu.id  
  instance_type = var.instance_type
  key_name = var.key_name
  security_groups = [aws_security_group.mlops_sg.name]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = true
  subnet_id = data.aws_subnet.default_subnet.id
  availability_zone = var.availability_zone

  root_block_device {
    volume_size = 13 
    volume_type = "gp2"
  }

  credit_specification {
    cpu_credits = "standard"  
  }
  tags = {
    Name = "mlops-Server"
  }
}

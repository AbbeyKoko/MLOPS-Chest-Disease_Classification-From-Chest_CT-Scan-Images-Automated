#!/bin/bash
set -e
apt update -y
apt-get update -y
apt install -y docker.io awscli curl unzip

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Login to ECR
aws ecr get-login-password --region ${AWS_REGION} | docker login \
  --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Write docker-compose file
cat > /home/ubuntu/docker-compose.yml <<EOF
${docker_compose}
EOF

cd /home/ubuntu
docker-compose up -d

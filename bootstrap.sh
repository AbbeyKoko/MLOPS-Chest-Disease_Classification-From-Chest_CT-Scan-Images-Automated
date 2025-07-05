#!/bin/bash

set -euo pipefail

cd terraform

echo "=== Running Terraform to provision infrastructure ==="
terraform init
terraform plan -out=secure.tfplan
terraform apply -auto-approve secure.tfplan 

echo "=== Extracting outputs for Ansible ==="
tf_outputs=$(terraform output -json)
# jenkins_elastic_ip=$(terraform output -raw jenkins_elastic_ip)
# mlops_elastic_ip=$(terraform output -raw mlops_elastic_ip)
# JENKINS_HOST=$(terraform output -raw JENKINS_URL)
# JENKINS_USER=$(terraform output -raw JENKINS_USER)
# JENKINS_PASSWORD=$(terraform output -raw JENKINS_PASSWORD)
# JENKINS_PIPELINE=$(terraform output -raw JENKINS_PIPELINE)
# PRIVATE_KEY_PATH=$(terraform output -raw private_key_path)
# ECR_REPO=$(terraform output -raw ECR_REPOSITORY)
# IMAGE_TAG=$(terraform output -raw IMAGE_TAG)
# AWS_ACCOUNT_ID=$(terraform output -raw AWS_ACCOUNT_ID)
# AWS_REGION=$(terraform output -raw AWS_REGION)
# AWS_ACCESS_KEY_ID=$(terraform output -raw AWS_ACCESS_KEY_ID)
# AWS_SECRET_ACCESS_KEY=$(terraform output -raw AWS_SECRET_ACCESS_KEY)
# GITHUB_REPO=$(terraform output -raw GITHUB_REPO)
# GITHUB_TOKEN=$(terraform output -raw GITHUB_TOKEN)

cd ../ansible

echo "=== Updating Ansible vars from Terraform ==="

if ! command -v yq &> /dev/null; then
  echo "Installing yq via Homebrew..."
  brew install yq
fi

GROUP_VARS="./group_vars/all.yml"

# Map Terraform output keys to Ansible variable names
ansible-vault decrypt group_vars/all.yml --vault-password-file vault_pass.txt


declare -a tf_keys=(
  jenkins_elastic_ip
  mlops_elastic_ip
  JENKINS_URL
  JENKINS_USER
  JENKINS_PASSWORD
  JENKINS_PIPELINE
  private_key_path
  ECR_REPOSITORY
  IMAGE_TAG
  AWS_ACCOUNT_ID
  AWS_REGION
  AWS_ACCESS_KEY_ID
  AWS_SECRET_ACCESS_KEY
  GITHUB_REPO
  GITHUB_TOKEN
)

declare -a ansible_keys=(
  jenkins_elastic_ip
  mlops_elastic_ip
  jenkins_host
  jenkins_user
  jenkins_password
  jenkins_pipeline
  private_key_path
  ecr_repo
  image_tag
  aws_account_id
  aws_region
  aws_access_key_id
  aws_secret_access_key
  github_repo
  github_token
)

# Parse all terraform outputs once (assumed done before)
for i in "${!tf_keys[@]}"; do
  tf_key="${tf_keys[$i]}"
  ansible_key="${ansible_keys[$i]}"

  # Extract the raw value for this key from Terraform outputs
  value=$(echo "$tf_outputs" | jq -r ".${tf_key}.value // empty")

  if [[ -n "$value" ]]; then
    echo "Injecting: $ansible_key"

    # 1) Update top-level variable
    yq -i ".${ansible_key} = \"${value}\"" "$GROUP_VARS"

    # 2) If this variable corresponds to a Jenkins secret (match by secret_id), update its secret_value
    case "$ansible_key" in
      ecr_repo)
        yq -i '(.jenkins_secrets[] | select(.secret_id == "ECR_REPOSITORY") | .secret_value) = "'"${value}"'"' "$GROUP_VARS"
        ;;
      image_tag)
        yq -i '(.jenkins_secrets[] | select(.secret_id == "IMAGE_TAG") | .secret_value) = "'"${value}"'"' "$GROUP_VARS"
        ;;
      aws_account_id)
        yq -i '(.jenkins_secrets[] | select(.secret_id == "AWS_ACCOUNT_ID") | .secret_value) = "'"${value}"'"' "$GROUP_VARS"
        ;;
      aws_access_key_id)
        yq -i '(.jenkins_secrets[] | select(.secret_id == "AWS_ACCESS_KEY_ID") | .secret_value) = "'"${value}"'"' "$GROUP_VARS"
        ;;
      aws_secret_access_key)
        yq -i '(.jenkins_secrets[] | select(.secret_id == "AWS_SECRET_ACCESS_KEY") | .secret_value) = "'"${value}"'"' "$GROUP_VARS"
        ;;
      private_key_path)
        # Update private_key_path top-level var too
        yq -i ".private_key_path = \"${value}\"" "$GROUP_VARS"
        # Also update the nested ssh secret's private_key_path (append full path)
        yq -i '(.jenkins_secrets[] | select(.secret_id == "ssh_key") | .private_key_path) = "/home/jenkins/'"${value}"'"' "$GROUP_VARS"
        ;;
    esac

  else
    echo "Skipping '${tf_key}': no Terraform output found."
  fi
done

echo "group_vars/all.yml updated with top-level vars and jenkins_secrets."

echo "=== Generating Ansible Inventory ==="
JENKINS_IP=$(echo "$tf_outputs" | jq -r ".jenkins_elastic_ip.value // empty")
RUNTIME_IP=$(echo "$tf_outputs" | jq -r ".mlops_elastic_ip.value // empty")
PRIVATE_KEY_PATH=$(echo "$tf_outputs" | jq -r ".private_key_path.value // empty")


cat > inventory.ini <<EOF
[jenkins_server]
${JENKINS_IP} ansible_user=ubuntu ansible_ssh_private_key_file=../terraform/${PRIVATE_KEY_PATH}

[mlops_server]
${RUNTIME_IP} ansible_user=ubuntu ansible_ssh_private_key_file=../terraform/${PRIVATE_KEY_PATH}

[github]
localhost ansible_connection=local
EOF

echo "Generated inventory.ini"

echo "=== Bootstrapping Jenkins using Ansible ==="
# install required Ansible collections
ansible-galaxy collection install -r requirements.yml
#encrypt tokens
VAULT_PASS_FILE="vault_pass.txt"
# Set your vault password (you can also prompt the user if needed)
# echo "your_strong_vault_password" > "$VAULT_PASS_FILE"
# chmod 600 "$VAULT_PASS_FILE"

ansible-vault encrypt group_vars/all.yml --vault-password-file vault_pass.txt
ANSIBLE_HOST_KEY_CHECKING=False \
ansible-playbook -i inventory.ini playbooks/bootstrap.yml --vault-password-file vault_pass.txt

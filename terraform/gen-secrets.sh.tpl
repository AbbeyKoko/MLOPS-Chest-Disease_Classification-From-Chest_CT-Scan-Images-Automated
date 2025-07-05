#!/bin/bash
set -e

#####################
echo "Extracting Terraform outputs..."
terraform output -json > tf_outputs.json

REQUIRED_KEYS=("JENKINS_URL" "JENKINS_USER" "JENKINS_API_TOKEN" "JENKINS_PIPELINE")

for key in "$${REQUIRED_KEYS[@]}"; do
  if ! jq -e --arg k "$$key" '.[$k]' tf_outputs.json > /dev/null; then
    echo "Missing Terraform output: $$key"
    exit 1
  fi
done

### Step 1: Install GitHub CLI (gh) if not found
if ! command -v gh &> /dev/null; then
  echo "Installing GitHub CLI..."
  if [[ "$$OSTYPE" == "linux-gnu"* ]]; then
    type -p curl >/dev/null || sudo apt install curl -y
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update
    sudo apt install gh -y
  else
    echo "Unsupported OS for automated install. Install gh manually."
    exit 1
  fi
fi

### Step 2: Authenticate gh using GitHub token
echo "${GITHUB_TOKEN}" | gh auth login --with-token --hostname github.com

### Step 3: Generate .env and .json output files
echo "Writing secrets.env file..."

cat > secrets.env <<EOF
JENKINS_URL=$(jq -r '.JENKINS_URL.value' tf_outputs.json)
JENKINS_USER=$(jq -r '.JENKINS_USER.value' tf_outputs.json)
JENKINS_API_TOKEN=$(jq -r '.JENKINS_API_TOKEN.value' tf_outputs.json)
JENKINS_PIPELINE=$(jq -r '.JENKINS_PIPELINE.value' tf_outputs.json)
EOF

echo "Generated: secrets.env"

jq -r 'to_entries | map({key: .key, value: .value.value}) | from_entries' tf_outputs.json > secrets.json
echo "Generated: secrets.json"

### Step 4: Upload to GitHub repo as secrets
echo "Setting GitHub Secrets in repo: ${GITHUB_REPO}"

gh secret set JENKINS_URL --repo "${GITHUB_REPO}" --body "$(jq -r '.JENKINS_URL.value' tf_outputs.json)"
gh secret set JENKINS_USER --repo "${GITHUB_REPO}" --body "$(jq -r '.JENKINS_USER.value' tf_outputs.json)"
gh secret set JENKINS_API_TOKEN --repo "${GITHUB_REPO}" --body "$(jq -r '.JENKINS_API_TOKEN.value' tf_outputs.json)"
gh secret set JENKINS_PIPELINE --repo "${GITHUB_REPO}" --body "$(jq -r '.JENKINS_PIPELINE.value' tf_outputs.json)"

echo "GitHub Actions Secrets pushed to ${GITHUB_REPO}"

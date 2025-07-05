#!/bin/bash
set -euo pipefail
exec > >(tee /var/log/jenkins-bootstrap.log | logger -t jenkins-bootstrap -s 2>/dev/console) 2>&1

# Terraform-provided values
JENKINS_URL="${JENKINS_URL}"
JENKINS_USER="${JENKINS_USER}"
JENKINS_PASSWORD="${JENKINS_PASSWORD}"
GITHUB_REPO="${GITHUB_REPO}"
JENKINS_PIPELINE="${JENKINS_PIPELINE}"
JENKINS_CLI="/var/cache/jenkins/war/WEB-INF/jenkins-cli.jar"

echo "Updating system..."
sudo apt update -y
sudo apt install -y openjdk-17-jdk awscli unzip jq curl git

# Install Docker
if ! command -v docker &> /dev/null; then
  echo "Installing Docker..."
  curl -fsSL https://get.docker.com -o get-docker.sh
  sudo sh get-docker.sh
fi

sudo usermod -aG docker ubuntu
sudo usermod -aG docker jenkins || true

# Install Jenkins
if [ ! -f /usr/bin/jenkins ]; then
  echo "Installing Jenkins..."
  curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
  echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
  sudo apt update
  sudo apt install -y jenkins
fi

# Disable setup wizard
echo "Disabling setup wizard..."
echo 'JAVA_ARGS="\$JAVA_ARGS -Djenkins.install.runSetupWizard=false"' | sudo tee -a /etc/default/jenkins

# Preconfigure admin user
echo "Preconfiguring admin user..."
sudo mkdir -p /var/lib/jenkins/init.groovy.d
sudo tee /var/lib/jenkins/init.groovy.d/basic-security.groovy > /dev/null <<EOF
import jenkins.model.*
import hudson.security.*

def instance = Jenkins.getInstance()
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount($JENKINS_USER, $JENKINS_PASSWORD)
instance.setSecurityRealm(hudsonRealm)

def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)

instance.save()
println("Admin user created by Groovy init script")
EOF

sudo chown -R jenkins:jenkins /var/lib/jenkins/init.groovy.d

echo "Starting Jenkins..."
sudo systemctl enable jenkins
sudo systemctl restart jenkins

# Disable setup wizard
echo "Disabling setup wizard..."
echo 'JAVA_ARGS="\$JAVA_ARGS -Djenkins.install.runSetupWizard=false"' | sudo tee -a /etc/default/jenkins

# Wait for Jenkins to be up and login page to be available
echo "Waiting for Jenkins to be ready for CLI..."
for i in {1..30}; do
  if curl -sSf $JENKINS_URL/login >/dev/null; then
    echo "Jenkins is up."
    break
  else
    echo "Jenkins not ready yet, waiting 10s..."
    sleep 10
  fi
done



if [ ! -f $JENKINS_CLI ]; then
  echo "Downloading Jenkins CLI..."
  curl -L $JENKINS_URL/jnlpJars/jenkins-cli.jar -o $JENKINS_CLI
fi

# Optionally, wait for CLI to be ready
for i in {1..30}; do
  if java -jar $JENKINS_CLI -s $JENKINS_URL who-am-i --username $JENKINS_USER --password $JENKINS_PASSWORD >/dev/null 2>&1; then
    echo "Jenkins CLI is ready."
    break
  else
    echo "Jenkins CLI not ready yet, waiting 10s..."
    sleep 10
  fi
done

# Install plugins
PLUGINS="workflow-aggregator git docker-workflow blueocean credentials-binding aws-credentials ssh-agent"

echo "Installing plugins..."
for plugin in $PLUGINS; do
  java -jar $JENKINS_CLI -s $JENKINS_URL -auth $JENKINS_USER:$JENKINS_PASSWORD install-plugin $plugin -deploy
done

echo "Restarting Jenkins after plugin install..."
java -jar $JENKINS_CLI -s $JENKINS_URL -auth $JENKINS_USER:$JENKINS_PASSWORD safe-restart
sleep 30

# Wait for Jenkins to be up and login page to be available
echo "Waiting for Jenkins to be ready for CLI..."
for i in {1..30}; do
  if curl -sSf $JENKINS_URL/login >/dev/null; then
    echo "Jenkins is up."
    break
  else
    echo "Jenkins not ready yet, waiting 10s..."
    sleep 10
  fi
done

# Optionally, wait for CLI to be ready
for i in {1..30}; do
  if java -jar $JENKINS_CLI -s $JENKINS_URL who-am-i --username $JENKINS_USER --password $JENKINS_PASSWORD >/dev/null 2>&1; then
    echo "Jenkins CLI is ready."
    break
  else
    echo "Jenkins CLI not ready yet, waiting 10s..."
    sleep 10
  fi
done


# Create a pipeline job from GitHub
echo "Creating pipeline job loading Jenkinsfile from GitHub..."

JOB_CONFIG_XML="/tmp/sample-pipeline-job.xml"
sudo tee $JOB_CONFIG_XML > /dev/null <<EOF
<flow-definition plugin="workflow-job@2.40">
  <description>Pipeline from GitHub repo</description>
  <keepDependencies>false</keepDependencies>
  <properties/>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps@2.95">
    <scm class="hudson.plugins.git.GitSCM" plugin="git@4.15.1">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>$GITHUB_REPO</url>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/main</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class="list"/>
      <extensions/>
    </scm>
    <scriptPath>.jenkins/Jenkinsfile</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <triggers/>
</flow-definition>
EOF

java -jar $JENKINS_CLI -s $JENKINS_URL -auth $JENKINS_USER:$JENKINS_PASSWORD create-job $JENKINS_PIPELINE < $JOB_CONFIG_XML

# Wait until Jenkins is up
echo "Waiting for Jenkins to start..."
while ! curl -s --fail "$JENKINS_URL/login" >/dev/null; do
  sleep 5
done
sleep 20


# Generate API token
echo "Generating API token for admin..."
sudo tee /tmp/create-admin-token.groovy > /dev/null <<EOF
import jenkins.model.*
import hudson.model.*
import jenkins.security.*

def user = User.get($JENKINS_USER, true)
def tokenName = "terraform-token"
def apiTokenProperty = user.getProperty(jenkins.security.ApiTokenProperty.class)
def existing = apiTokenProperty.tokenStore.tokenList.find { it.name == tokenName }

if (existing) {
  println("Existing token: " + existing.plainValue)
} else {
  def token = apiTokenProperty.tokenStore.generateNewToken(tokenName)
  user.save()
  println("Generated token: " + token.plainValue)
}
EOF

TOKEN_OUTPUT=\$(java -jar $JENKINS_CLI -s $JENKINS_URL -auth $JENKINS_USER:$JENKINS_PASSWORD groovy < /tmp/create-admin-token.groovy)
echo $TOKEN_OUTPUT | sudo tee /tmp/jenkins_token_output.txt

echo "Jenkins bootstrapping complete!"

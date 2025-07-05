#!/bin/bash

tf_outputs=$(terraform output -json)

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

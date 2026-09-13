#!/usr/bin/env bash
set -euo pipefail

echo "=== AWS identity ==="
aws sts get-caller-identity --output json

echo "=== Terraform outputs ==="
terraform -chdir=terraform/main output

echo "=== Application HTTP ==="
WEB_IP="$(terraform -chdir=terraform/main output -raw web_elastic_ip)"
curl -fsS -o /dev/null -w 'HTTP %{http_code}\n' "http://${WEB_IP}"

echo "=== EC2 instances ==="
aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=syam9-devops-final" "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].{Name:Tags[?Key==`Name`]|[0].Value,PrivateIP:PrivateIpAddress,PublicIP:PublicIpAddress}' \
  --output table

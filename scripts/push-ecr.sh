#!/usr/bin/env bash
set -euo pipefail

REGION="${AWS_REGION:-ap-southeast-1}"
REPO_NAME="devops-final-app"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
IMAGE="${REGISTRY}/${REPO_NAME}:latest"

aws ecr get-login-password --region "$REGION" \
  | docker login --username AWS --password-stdin "$REGISTRY"

docker build -t "$IMAGE" "$ROOT_DIR/app"
docker push "$IMAGE"

echo "Pushed: $IMAGE"

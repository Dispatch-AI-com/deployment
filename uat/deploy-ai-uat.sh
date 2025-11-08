#!/usr/bin/env bash
set -euo pipefail

REGION="ap-southeast-2"
PROJECT="dispatchai-uat"
UAT_BACKEND_AI_ECR="381492119078.dkr.ecr.ap-southeast-2.amazonaws.com/dispatchai-uat-backend-ai"
IMAGE_TAG="${1:?Usage: deploy-ai-uat.sh <image-tag>}"
export UAT_BACKEND_AI_ECR
export IMAGE_TAG

#######################################################
# Fetch environment variables from parameter store
#######################################################
# Parameter Store Path
PREFIX="/dispatchai/uat/backend-api/env/"

aws ssm get-parameters-by-path \
  --region "$REGION" \
  --path "$PREFIX" \
  --recursive \
  --with-decryption \
  --query 'Parameters[].[Name,Value]' \
  --output json |
jq -r 'sort_by(.[0])[] | "\((.[0]|split("/")|last))=\(.[1])"' > .env.uat

echo "========================================================================"
echo "🚀 Deploying DispatchAI AI Services using Image Tag:$IMAGE_TAG 🚀"
echo "========================================================================"
echo "Checking for Docker network ..."
if ! docker network inspect dispatchai-uat-network >/dev/null 2>&1; then
  echo "Creating dispatchai-uat-network ..."
  docker network create dispatchai-uat-network
fi

echo "----------------------------------------------"
echo "Stopping and removing old API container (if any)..."
docker compose -p "$PROJECT" -f "docker-compose.uat.yml" stop ai
docker compose -p "$PROJECT" -f "docker-compose.uat.yml" rm -f ai

echo "----------------------------------------------"
echo "Pulling images for AI service ..."
docker compose -p "$PROJECT" -f "docker-compose.uat.yml" pull ai

echo "----------------------------------------------"
echo "Starting new AI container ..."
docker compose -p "$PROJECT" -f "docker-compose.uat.yml" up -d --force-recreate ai

echo "========================================================================"
echo "✅ AI service deployed successfully! ✅"
echo "========================================================================"

echo "Deleting unused images ..."
docker image prune -a -f

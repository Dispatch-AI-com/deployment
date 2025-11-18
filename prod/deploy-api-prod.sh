#!/usr/bin/env bash
set -euo pipefail

REGION="ap-southeast-2"
PROJECT="dispatchai-prod"
PROD_BACKEND_API_ECR="381492119078.dkr.ecr.ap-southeast-2.amazonaws.com/dispatchai-prod-backend-api"
IMAGE_TAG="${1:?Usage: deploy-api-prod.sh <image-tag>}"
export PROD_BACKEND_API_ECR
export IMAGE_TAG

#######################################################
# Fetch environment variables from parameter store
#######################################################
# Parameter Store Path
PREFIX="/dispatchai/prod/backend-api/env/"

aws ssm get-parameters-by-path \
  --region "$REGION" \
  --path "$PREFIX" \
  --recursive \
  --with-decryption \
  --query 'Parameters[].[Name,Value]' \
  --output json |
jq -r 'sort_by(.[0])[] | "\((.[0]|split("/")|last))=\(.[1])"' > .env.prod

echo "========================================================================"
echo "🚀 Deploying DispatchAI API Service to PRODUCTION using Image Tag:$IMAGE_TAG 🚀"
echo "========================================================================"
echo "Checking for Docker network ..."
if ! docker network inspect dispatchai-prod-network >/dev/null 2>&1; then
  echo "Creating dispatchai-prod-network ..."
  docker network create dispatchai-prod-network
fi

echo "----------------------------------------------"
echo "Stopping and removing old API container (if any)..."
docker compose -p "$PROJECT" -f "docker-compose.prod.yml" stop api
docker compose -p "$PROJECT" -f "docker-compose.prod.yml" rm -f api

echo "----------------------------------------------"
echo "Pulling images for API service ..."
docker compose -p "$PROJECT" -f "docker-compose.prod.yml" pull api

echo "----------------------------------------------"
echo "Starting new API container ..."
docker compose -p "$PROJECT" -f "docker-compose.prod.yml" up -d --force-recreate api

echo "========================================================================"
echo "✅ API service deployed successfully to PRODUCTION! ✅"
echo "========================================================================"

echo "Deleting unused images ..."
docker image prune -a -f


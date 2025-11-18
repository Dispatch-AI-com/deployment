#!/usr/bin/env bash
set -euo pipefail

REGION="ap-southeast-2"
PROJECT="dispatchai-prod"
PROD_FRONTEND_ECR="381492119078.dkr.ecr.ap-southeast-2.amazonaws.com/dispatchai-prod-frontend"
IMAGE_TAG="${1:?Usage: deploy-frontend-prod.sh <image-tag>}"

# Export environment variables for docker-compose
export PROD_FRONTEND_ECR
export IMAGE_TAG

echo "========================================================================"
echo "🚀 Deploying DispatchAI Frontend to PRODUCTION using Image Tag:$IMAGE_TAG 🚀"
echo "========================================================================"

echo "----------------------------------------------"
echo "Logging in to Amazon ECR ..."
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$PROD_FRONTEND_ECR"

echo "Checking for Docker network ..."
if ! docker network inspect dispatchai-prod-network >/dev/null 2>&1; then
  echo "Creating dispatchai-prod-network ..."
  docker network create dispatchai-prod-network
fi

echo "----------------------------------------------"
echo "Stopping and removing old frontend container (if any)..."
docker compose -p "$PROJECT" -f "docker-compose.prod.yml" stop frontend
docker compose -p "$PROJECT" -f "docker-compose.prod.yml" rm -f frontend

echo "----------------------------------------------"
echo "Pulling images for frontend service ..."
docker compose -p "$PROJECT" -f "docker-compose.prod.yml" pull frontend

echo "----------------------------------------------"
echo "Starting new frontend container ..."
docker compose -p "$PROJECT" -f "docker-compose.prod.yml" up -d --force-recreate frontend

echo "========================================================================"
echo "✅ Frontend service deployed successfully to PRODUCTION! ✅"
echo "========================================================================"

echo "Deleting unused images ..."
docker image prune -a -f


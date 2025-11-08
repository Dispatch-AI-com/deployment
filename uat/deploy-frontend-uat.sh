#!/usr/bin/env bash
set -euo pipefail

REGION="ap-southeast-2"
PROJECT="dispatchai-uat"
UAT_FRONTEND_ECR="381492119078.dkr.ecr.ap-southeast-2.amazonaws.com/dispatchai-uat-frontend"
IMAGE_TAG="${1:?Usage: deploy-frontend-uat.sh <image-tag>}"
export UAT_FRONTEND_ECR
export IMAGE_TAG

echo "========================================================================"
echo "🚀 Deploying DispatchAI Frontend using Image Tag:$IMAGE_TAG 🚀"
echo "========================================================================"
echo "Checking for Docker network ..."
if ! docker network inspect dispatchai-uat-network >/dev/null 2>&1; then
  echo "Creating dispatchai-uat-network ..."
  docker network create dispatchai-uat-network
fi

echo "----------------------------------------------"
echo "Stopping and removing old frontend container (if any)..."
docker compose -p "$PROJECT" -f "docker-compose.uat.yml" stop frontend
docker compose -p "$PROJECT" -f "docker-compose.uat.yml" rm -f frontend

echo "----------------------------------------------"
echo "Pulling images for frontend service ..."
docker compose -p "$PROJECT" -f "docker-compose.uat.yml" pull frontend

echo "----------------------------------------------"
echo "Starting new frontend container ..."
docker compose -p "$PROJECT" -f "docker-compose.uat.yml" up -d --force-recreate frontend

echo "========================================================================"
echo "✅ Frontend service deployed successfully! ✅"
echo "========================================================================"

echo "Deleting unused images ..."
docker image prune -a -f

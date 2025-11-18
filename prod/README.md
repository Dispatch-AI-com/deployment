# Production Deployment Scripts

This directory contains deployment scripts for the production environment.

## Files

- `deploy-frontend-prod.sh` - Deploy frontend service
- `deploy-api-prod.sh` - Deploy backend API service
- `deploy-ai-prod.sh` - Deploy AI service
- `docker-compose.prod.yml` - Docker Compose configuration for production

## Usage

These scripts are automatically called by GitHub Actions workflow when deploying to production. They should be placed on the EC2 instance at:

```
/home/ubuntu/devops/deployment/prod/
```


## Deployment Process

1. GitHub Actions workflow is triggered manually
2. User selects:
   - Git tag to deploy
   - Services to deploy (frontend, api, ai - can select multiple)
3. Workflow validates inputs and checks out the specified tag
4. For each selected service:
   - Runs tests and linting
   - Builds Docker image
   - Pushes to ECR
   - Deploys via AWS SSM to EC2
5. EC2 instance runs the deployment script which:
   - Pulls the new image
   - Stops old container
   - Starts new container
   - Cleans up unused images

## Network

The scripts create a Docker network `dispatchai-prod-network` if it doesn't exist. All services run on this network.

## Ports

- Frontend: `3000`
- API: `4000`
- AI: `8000`

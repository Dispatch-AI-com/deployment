# Deployment Guide - DispatchAI Platform

This directory contains Docker Compose configurations and deployment scripts for the DispatchAI Platform. It documents the available environments, quick commands, deployment scripts, and provides comprehensive guidance for AI coding tools to understand the deployment architecture.

## 📁 Directory Structure

```
deployment/
├── README.md                    # This file - comprehensive deployment guide
├── dev/                         # Development environment
│   └── docker-compose.dev.yml  # Local development compose file
├── uat/                         # User Acceptance Testing environment
│   ├── docker-compose.uat.yml  # UAT compose file
│   ├── deploy-frontend-uat.sh # Helper script to deploy frontend to UAT
│   ├── deploy-api-uat.sh      # Helper script to deploy backend API to UAT
│   └── deploy-ai-uat.sh       # Helper script to deploy AI service to UAT
└── prod/                        # Production environment (empty for now)
```

## 🏗️ Architecture Overview

The DispatchAI Platform is a **monorepo** with three main services:

| Service | Tech Stack | Port | Container Name | Purpose |
|---------|------------|------|----------------|---------|
| **Frontend** | Next.js 15, React 19, TypeScript, Material-UI | 3000 | `dispatchai-frontend` | User dashboard, service management UI |
| **Backend** | NestJS 11, TypeScript, MongoDB, Redis | 4000 | `dispatchai-api` | REST API, business logic, telephony webhooks |
| **AI Service** | FastAPI, Python 3.11, LangGraph, OpenAI | 8000 | `dispatchai-ai` | AI conversation agent, call handling, dispatch |

### Infrastructure Services

| Service | Image | Port | Container Name | Purpose |
|---------|-------|------|----------------|---------|
| **MongoDB** | `mongo:7` | 27017 | `dispatchai-mongodb` | Primary database |
| **Redis** | `redis:7-alpine` | 6379 | `dispatchai-redis` | Caching, sessions, call state |

### Service Communication

```
┌─────────────┐      HTTP/REST      ┌─────────────┐
│  Frontend   │◄───────────────────►│   Backend   │
│  (Next.js)  │                     │  (NestJS)   │
└──────┬──────┘                     └──────┬──────┘
       │                                    │
       │ HTTP/REST                          │ HTTP/REST
       │                                    │
       ▼                                    ▼
┌─────────────┐                     ┌─────────────┐
│  AI Service │                     │   MongoDB   │
│  (FastAPI)  │                     │             │
└──────┬──────┘                     └─────────────┘
       │
       │ Redis (CallSkeleton, state)
       │
       ▼
┌─────────────┐
│    Redis    │
└─────────────┘
```

**Key Integration Points:**
- **Frontend ↔ Backend**: REST API calls via `NEXT_PUBLIC_API_URL`
- **Frontend ↔ AI Service**: Direct HTTP calls to `/api/ai/conversation`
- **Backend ↔ AI Service**: Redis for CallSkeleton storage, HTTP for summaries
- **Backend ↔ MongoDB**: Mongoose ODM for data persistence
- **AI Service ↔ Redis**: CallSkeleton storage, conversation state

## 🚀 Quick Start

### Prerequisites

- **Docker** & **Docker Compose** (v2.0+)
- **Git**
- **pnpm** (package manager) - Install: `npm install -g pnpm`
- **Node.js** 18+ (for local development without Docker)
- **Python** 3.11+ (for AI service local development without Docker)
- **AWS CLI** (for UAT/prod deployments)
- **SSH keys** configured (for UAT deployment)

### Development Environment Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd dispatchai-platform
   ```

2. **Configure environment variables**
   
   Create environment files at the repository root:
   ```bash
   # Root level - shared across services
   touch .env.shared .env.dev
   
   # Service-specific
   touch apps/backend/.env.local
   touch apps/frontend/.env.local
   touch apps/ai/.env.local
   ```
   
   See [Environment Variables](#-environment-variables) section for required values.

3. **Start all services**
   ```bash
   # From project root
   docker compose -f deployment/dev/docker-compose.dev.yml up --build -d
   
   # Or use pnpm scripts
   pnpm run dev:up
   ```

4. **Verify services are running**
   ```bash
   docker compose -f deployment/dev/docker-compose.dev.yml ps
   ```

5. **Access services**
   - Frontend: http://localhost:3000
   - Backend API: http://localhost:4000/api (Swagger: http://localhost:4000/api)
   - AI Service: http://localhost:8000/api (Docs: http://localhost:8000/docs)
   - MongoDB: localhost:27017
   - Redis: localhost:6379

## 📋 Common Commands

### Development Commands

```bash
# Start all services
docker compose -f deployment/dev/docker-compose.dev.yml up -d --build

# Stop all services
docker compose -f deployment/dev/docker-compose.dev.yml down

# View logs (all services)
docker compose -f deployment/dev/docker-compose.dev.yml logs -f

# View logs for specific service
docker compose -f deployment/dev/docker-compose.dev.yml logs -f api
docker compose -f deployment/dev/docker-compose.dev.yml logs -f ai
docker compose -f deployment/dev/docker-compose.dev.yml logs -f frontend

# View last 100 lines
docker compose -f deployment/dev/docker-compose.dev.yml logs --tail=100

# Show running containers
docker compose -f deployment/dev/docker-compose.dev.yml ps

# Rebuild specific service
docker compose -f deployment/dev/docker-compose.dev.yml build api
docker compose -f deployment/dev/docker-compose.dev.yml up -d api

# Rebuild and restart specific service
docker compose -f deployment/dev/docker-compose.dev.yml up -d --build api

# Stop and remove volumes (clean slate)
docker compose -f deployment/dev/docker-compose.dev.yml down -v
```

### Service-Specific Commands

```bash
# Restart single service
docker compose -f deployment/dev/docker-compose.dev.yml restart api

# Execute command in container
docker exec -it dispatchai-api sh
docker exec -it dispatchai-ai bash
docker exec -it dispatchai-frontend sh

# View container resource usage
docker stats dispatchai-api dispatchai-ai dispatchai-frontend
```

## 🔧 Environment Variables

### Root `.env.shared` (Shared across all services)

```bash
# MongoDB
MONGODB_URI=mongodb://mongo:27017/dispatchai

# Redis
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_URL=redis://redis:6379

# Twilio (for Backend)
TWILIO_ACCOUNT_SID=your_account_sid
TWILIO_AUTH_TOKEN=your_auth_token
TWILIO_PHONE_NUMBER=+1234567890

# OpenAI (for AI Service)
OPENAI_API_KEY=sk-...
OPENAI_MODEL=gpt-4o-mini
```

### Root `.env.dev` (Development-specific overrides)

```bash
NODE_ENV=development
DEBUG=true
LOG_LEVEL=debug
```

### Backend `.env.local` (`apps/backend/.env.local`)

```bash
# Server
PORT=4000
NODE_ENV=development

# JWT
JWT_SECRET=your_jwt_secret_key_here
JWT_EXPIRES_IN=7d

# Google OAuth
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret
GOOGLE_REDIRECT_URI=http://localhost:4000/api/auth/google/callback

# Stripe
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...

# CORS
CORS_ORIGIN=http://localhost:3000

# Database (from .env.shared)
MONGODB_URI=mongodb://mongo:27017/dispatchai

# Redis (from .env.shared)
REDIS_HOST=redis
REDIS_PORT=6379
```

### Frontend `.env.local` (`apps/frontend/.env.local`)

```bash
# API URLs
NEXT_PUBLIC_API_URL=http://localhost:4000/api
NEXT_PUBLIC_AI_URL=http://localhost:8000/api

# Google
NEXT_PUBLIC_GOOGLE_CLIENT_ID=your_google_client_id
NEXT_PUBLIC_GOOGLE_MAPS_API_KEY=your_google_maps_api_key

# Environment
NODE_ENV=development
```

### AI Service `.env.local` (`apps/ai/.env.local`)

```bash
# OpenAI
OPENAI_API_KEY=sk-...
OPENAI_MODEL=gpt-4o-mini
OPENAI_MAX_TOKENS=2500
OPENAI_TEMPERATURE=0.0

# Redis (from .env.shared)
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_URL=redis://redis:6379

# Server
API_PREFIX=/api
DEBUG=true
```

## 🧪 Health Checks & Testing

### Service Health Endpoints

```bash
# Backend API
curl http://localhost:4000/api/health

# AI Service
curl http://localhost:8000/api/health

# Frontend (no health endpoint, check root)
curl http://localhost:3000
```

### Database Connections

```bash
# MongoDB
docker exec -it dispatchai-mongodb mongosh
use dispatchai
show collections
db.users.find().pretty()

# Redis
docker exec -it dispatchai-redis redis-cli
KEYS *
GET callskeleton:CA1234567890
```

### Container Status

```bash
# Check all containers
docker compose -f deployment/dev/docker-compose.dev.yml ps

# Check specific container logs
docker logs dispatchai-api -f
docker logs dispatchai-ai -f
docker logs dispatchai-frontend -f
```

## 🐛 Troubleshooting

### Port Conflicts

**Issue**: Port already in use (3000, 4000, 8000, 27017, 6379)

**Solution**:
```bash
# Find process using port
# Windows
netstat -ano | findstr :4000
# Linux/Mac
lsof -i :4000

# Stop conflicting service or change port in docker-compose.dev.yml
```

### Container Won't Start

**Issue**: Container exits immediately or fails to start

**Solution**:
```bash
# Check logs
docker logs dispatchai-api
docker logs dispatchai-ai

# Check container status
docker ps -a

# Restart with fresh build
docker compose -f deployment/dev/docker-compose.dev.yml down -v
docker compose -f deployment/dev/docker-compose.dev.yml up --build -d
```

### Database Connection Issues

**Issue**: Services can't connect to MongoDB or Redis

**Solution**:
```bash
# Verify containers are running
docker compose -f deployment/dev/docker-compose.dev.yml ps

# Check network connectivity
docker exec -it dispatchai-api ping mongo
docker exec -it dispatchai-api ping redis

# Verify environment variables
docker exec -it dispatchai-api env | grep MONGODB
docker exec -it dispatchai-api env | grep REDIS
```

### Volume Issues

**Issue**: Data not persisting or stale data

**Solution**:
```bash
# Remove volumes and start fresh
docker compose -f deployment/dev/docker-compose.dev.yml down -v
docker compose -f deployment/dev/docker-compose.dev.yml up -d

# Inspect volumes
docker volume ls
docker volume inspect dispatchai_mongo-data
```

### Build Failures

**Issue**: Docker build fails

**Solution**:
```bash
# Clean build cache
docker builder prune

# Rebuild without cache
docker compose -f deployment/dev/docker-compose.dev.yml build --no-cache

# Check Dockerfile syntax
docker build -f apps/backend/Dockerfile.dev apps/backend
```

## 🚢 UAT Deployment

### Overview

UAT (User Acceptance Testing) deployments use pre-built Docker images stored in AWS ECR. The deployment process involves:

1. Building and tagging images (usually done by CI/CD)
2. Pushing images to AWS ECR
3. SSH to UAT EC2 instance
4. Pulling latest images
5. Restarting services with docker-compose

### Location

- **Compose file**: `deployment/uat/docker-compose.uat.yml`
- **Deployment scripts**: `deployment/uat/deploy-*-uat.sh`
- **EC2 directory**: `/opt/dispatchai-platform` (on UAT server)

### Deployment Scripts

Three helper scripts are available for deploying individual services:

#### `deploy-frontend-uat.sh`

Deploys frontend service to UAT.

**Usage**:
```bash
cd deployment/uat
./deploy-frontend-uat.sh <image-tag>
```

**What it does**:
1. Creates Docker network if needed
2. Stops and removes old frontend container
3. Pulls new image from ECR
4. Starts new container
5. Cleans up unused images

#### `deploy-api-uat.sh`

Deploys backend API service to UAT.

**Usage**:
```bash
cd deployment/uat
./deploy-api-uat.sh <image-tag>
```

#### `deploy-ai-uat.sh`

Deploys AI service to UAT.

**Usage**:
```bash
cd deployment/uat
./deploy-ai-uat.sh <image-tag>
```

### Manual UAT Deployment

If you need to deploy manually:

```bash
# 1. SSH to UAT EC2
ssh ubuntu@<uat-host>

# 2. Navigate to project
cd /opt/dispatchai-platform

# 3. Login to AWS ECR
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
aws ecr get-login-password --region ap-southeast-2 \
  | docker login --username AWS --password-stdin \
  ${ACCOUNT_ID}.dkr.ecr.ap-southeast-2.amazonaws.com

# 4. Pull latest images
cd deployment/uat
export IMAGE_TAG=latest  # or specific tag
docker compose -f docker-compose.uat.yml pull

# 5. Restart services
docker compose -f docker-compose.uat.yml up -d

# 6. Verify
docker compose -f docker-compose.uat.yml ps
docker compose -f docker-compose.uat.yml logs -f
```

### UAT Environment Variables

UAT uses `.env.uat` file on the EC2 instance:

```bash
# Located at: /opt/dispatchai-platform/deployment/uat/.env.uat

# MongoDB (UAT database)
MONGODB_URI=mongodb://uat-mongo-host:27017/dispatchai-uat

# Redis (UAT cache)
REDIS_HOST=uat-redis-host
REDIS_PORT=6379

# API Keys (UAT credentials)
TWILIO_ACCOUNT_SID=uat_account_sid
OPENAI_API_KEY=uat_openai_key
# ... other UAT-specific values
```

### UAT ECR Registry

- **Account ID**: `381492119078`
- **Region**: `ap-southeast-2`
- **Registry**: `381492119078.dkr.ecr.ap-southeast-2.amazonaws.com`
- **Repositories**:
  - `dispatchai-frontend-uat`
  - `dispatchai-backend-uat`
  - `dispatchai-backend-ai-uat`

## 🔍 AI Coding Quick Reference

This section helps AI coding tools quickly locate code and understand the deployment architecture.

### Finding Code by Feature

#### Authentication & Authorization
- **Backend**: `apps/backend/src/modules/auth/`
- **Frontend**: `apps/frontend/src/app/auth/`, `apps/frontend/src/features/auth/`
- **API Endpoints**: `POST /api/auth/login`, `POST /api/auth/signup`, `GET /api/auth/me`

#### Call Handling & Telephony
- **Backend Twilio Integration**: `apps/backend/src/modules/telephony/`
- **Backend Webhooks**: `apps/backend/src/modules/telephony/telephony.controller.ts`
- **AI Conversation Handler**: `apps/ai/app/services/call_handler.py`
- **AI Conversation API**: `apps/ai/app/api/call.py`
- **Frontend Call UI**: `apps/frontend/src/app/admin/inbox/`
- **Call Logs**: `apps/backend/src/modules/calllog/`

#### Service Booking & Scheduling
- **Backend API**: `apps/backend/src/modules/service-booking/`
- **Frontend UI**: `apps/frontend/src/app/admin/booking/`
- **AI Scheduling**: `apps/ai/app/api/dispatch.py`
- **Calendar Integration**: `apps/backend/src/modules/google-calendar/`

#### Transcripts & Summaries
- **Backend Storage**: `apps/backend/src/modules/transcript/`
- **Backend Chunks**: `apps/backend/src/modules/transcript-chunk/`
- **AI Summary Generation**: `apps/ai/app/services/call_summary.py`
- **AI Summary API**: `apps/ai/app/api/summary.py`
- **Frontend Display**: `apps/frontend/src/app/admin/inbox/`

#### Email & Calendar
- **AI Email Service**: `apps/ai/app/services/ses_email.py`
- **AI Email API**: `apps/ai/app/api/email.py`
- **AI Calendar Dispatch**: `apps/ai/app/api/dispatch.py`
- **ICS Generation**: `apps/ai/app/services/ics_lib.py`

### Docker Compose Service Names

When referencing services in code or scripts:

- **Frontend**: `frontend` (service name), `dispatchai-frontend` (container name)
- **Backend**: `api` (service name), `dispatchai-api` (container name)
- **AI Service**: `ai` (service name), `dispatchai-ai` (container name)
- **MongoDB**: `mongo` (service name), `dispatchai-mongodb` (container name)
- **Redis**: `redis` (service name), `dispatchai-redis` (container name)

### Environment Variable Locations

- **Root shared**: `.env.shared` (MongoDB, Redis, Twilio, OpenAI)
- **Root dev**: `.env.dev` (development overrides)
- **Backend**: `apps/backend/.env.local` (JWT, OAuth, Stripe)
- **Frontend**: `apps/frontend/.env.local` (API URLs, Google keys)
- **AI Service**: `apps/ai/.env.local` (OpenAI, Redis)

### Service Ports & URLs

| Service | Port | Internal URL | External URL |
|---------|------|--------------|--------------|
| Frontend | 3000 | http://frontend:3000 | http://localhost:3000 |
| Backend | 4000 | http://api:4000 | http://localhost:4000 |
| AI Service | 8000 | http://ai:8000 | http://localhost:8000 |
| MongoDB | 27017 | mongodb://mongo:27017 | mongodb://localhost:27017 |
| Redis | 6379 | redis://redis:6379 | redis://localhost:6379 |

### Common File Paths

**Docker Compose Files:**
- Development: `deployment/dev/docker-compose.dev.yml`
- UAT: `deployment/uat/docker-compose.uat.yml`

**Dockerfiles:**
- Frontend Dev: `apps/frontend/Dockerfile.dev`
- Frontend UAT: `apps/frontend/Dockerfile.uat`
- Backend Dev: `apps/backend/Dockerfile.dev`
- Backend UAT: `apps/backend/Dockerfile.uat`
- AI Dev: `apps/ai/Dockerfile.dev`
- AI UAT: `apps/ai/Dockerfile.uat`

**Entry Points:**
- Frontend: `apps/frontend/src/app/layout.tsx`
- Backend: `apps/backend/src/main.ts`
- AI Service: `apps/ai/app/main.py`

## 📊 Monitoring & Logs

### Viewing Logs

```bash
# All services
docker compose -f deployment/dev/docker-compose.dev.yml logs -f

# Specific service
docker compose -f deployment/dev/docker-compose.dev.yml logs -f api
docker compose -f deployment/dev/docker-compose.dev.yml logs -f ai
docker compose -f deployment/dev/docker-compose.dev.yml logs -f frontend

# Last N lines
docker compose -f deployment/dev/docker-compose.dev.yml logs --tail=100

# Since timestamp
docker compose -f deployment/dev/docker-compose.dev.yml logs --since 10m
```

### Container Resource Usage

```bash
# All containers
docker stats

# Specific containers
docker stats dispatchai-api dispatchai-ai dispatchai-frontend
```

### Database Monitoring

```bash
# MongoDB stats
docker exec -it dispatchai-mongodb mongosh
use dispatchai
db.stats()

# Redis info
docker exec -it dispatchai-redis redis-cli
INFO stats
INFO memory
```

## 🔐 Security Best Practices

1. **Never commit secrets** - Use `.env` files and `.gitignore`
2. **Use environment-specific configs** - Separate dev/UAT/prod values
3. **Rotate credentials regularly** - Especially for production
4. **Limit container permissions** - Use non-root users in Dockerfiles
5. **Network isolation** - Use Docker networks to isolate services
6. **Health checks** - Monitor service health endpoints
7. **Log monitoring** - Watch for suspicious activity

## 📚 Additional Resources

- **Root README**: `README.md` - Overall project overview
- **Backend README**: `apps/backend/README.md` - Backend service details
- **Frontend README**: `apps/frontend/readme.md` - Frontend service details
- **AI Service README**: `apps/ai/readme.md` - AI service details
- **CI/CD README**: `.github/README.md` - GitHub Actions workflows

## 🚧 Production Deployment

The `deployment/prod/` directory is currently empty. Production deployment will follow the same pattern as UAT but with:

- **Stricter controls**: Pinned image tags (no `latest`)
- **Resource limits**: CPU and memory constraints
- **Monitoring**: Enhanced logging and metrics
- **Secrets management**: AWS Secrets Manager or similar
- **Rollback procedure**: Documented rollback process
- **Blue-green deployment**: Zero-downtime deployments
- **Health checks**: Automated health monitoring
- **Backup strategy**: Database and state backups

## 🤝 Contributing

When updating deployment configurations:

1. **Test locally** - Verify changes work in dev environment
2. **Update documentation** - Keep this README current
3. **Version control** - Commit compose files and scripts
4. **Environment variables** - Document new required variables
5. **Breaking changes** - Note any migration steps needed

## 📝 Notes

- **Network naming**: UAT uses `dispatchai-uat-network` (external network)
- **Image tags**: UAT uses `${IMAGE_TAG}` environment variable
- **Volume persistence**: MongoDB and Redis data persist in Docker volumes
- **Path consistency**: All scripts and documentation now use `deployment/` directory (previously `infra/`)

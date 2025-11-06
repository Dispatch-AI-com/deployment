# Deployment

This folder contains Docker Compose configurations and deployment scripts for the
DispatchAI Platform. It documents the available environments, quick commands, and
deployment scripts that the team uses for Development and UAT. The `prod` folder
is currently empty and will be populated when production deployment configuration
is added.

## Structure

deployment/
- README.md                # (this file) overview and usage
- dev/
  - docker-compose.dev.yml # Local development compose file
- uat/
  - docker-compose.uat.yml # UAT compose file
  - deploy-frontend-uat.sh  # Helper script to deploy frontend to UAT
  - deploy-api-uat.sh       # Helper script to deploy API to UAT
  - deploy-ai-uat.sh        # Helper script to deploy AI service to UAT
- prod/
  - (empty for now)

## Quick Reference

- Development compose: `deployment/dev/docker-compose.dev.yml`
- UAT compose & scripts: `deployment/uat/docker-compose.uat.yml` and the
  `deploy-*-uat.sh` scripts

Use the development compose to run the full stack locally. Use the UAT compose
and scripts for user-acceptance testing deployments.

## Development (Local)

Location: `deployment/dev/docker-compose.dev.yml`

Purpose: start local instances of the frontend, backend (API), and AI service,
plus any local dependencies (databases, caches) used during development.

Common actions (run from project root):

- Start services: use your repo's npm/pnpm scripts or run:
  docker compose -f deployment/dev/docker-compose.dev.yml up --build -d
- Stop services:
  docker compose -f deployment/dev/docker-compose.dev.yml down
- View logs:
  docker compose -f deployment/dev/docker-compose.dev.yml logs -f

Note: check the compose file for service ports and environment variables. The
project typically uses shared `.env` files at the repository root (for local
development) — do not commit secrets into the repo.

## UAT (User Acceptance Testing)

Location: `deployment/uat/docker-compose.uat.yml` and `deployment/uat/*.sh`

Purpose: deploy images built for the UAT environment. The `deploy-*-uat.sh`
scripts are thin helpers used by the team to push images and run remote compose
up (commonly via SSH to a UAT host). Open each script for exact commands and
required environment variables.

Typical workflow:

1. Build and tag images for UAT (CI usually does this).
2. Push images to a registry (e.g. AWS ECR).
3. SSH to the UAT host and run compose with `deployment/uat/docker-compose.uat.yml`.

The repo contains three scripts:

- `deploy-frontend-uat.sh` — deploy frontend image to UAT host
- `deploy-api-uat.sh` — deploy backend API image to UAT host
- `deploy-ai-uat.sh` — deploy AI service image to UAT host

Read the top of each script for required environment variables (registry
credentials, host, SSH key path, etc.).

## Production

The `deployment/prod` directory is empty. Production deployment will follow the
same pattern as UAT but with stricter controls: pinned image tags, monitoring,
resource limits, secrets management, and a documented rollback procedure.

## Health checks and troubleshooting

Each service generally exposes a health endpoint; check the individual app
README files under `apps/` for exact endpoints. Common checks:

- API: curl http://localhost:<api-port>/api/health
- AI: curl http://localhost:<ai-port>/api/health
- Docker container status:
  docker compose -f deployment/dev/docker-compose.dev.yml ps
- View logs:
  docker compose -f deployment/dev/docker-compose.dev.yml logs <service>

If you run into port conflicts or stale volumes, bring the compose stack down
and start again:

docker compose -f deployment/dev/docker-compose.dev.yml down -v
docker compose -f deployment/dev/docker-compose.dev.yml up --build -d

## Best practices

- Use environment-specific `.env` files stored outside the repository for
  secrets and host-specific values.
- In UAT/Prod, prefer fixed image tags instead of `latest`.
- Keep the `deploy-*.sh` scripts small and idempotent. Prefer CI-driven image
  builds and registry pushes.

## Where to look next

- App READMEs: `apps/frontend`, `apps/backend`, `apps/ai`
- Root README: `README.md`
- CI workflows (if present) for build and deploy automation

If you'd like, I can:
- add usage examples for the UAT scripts (once you confirm typical environment
  variables), or
- create a small checklist for deploying to UAT that matches your CI process.

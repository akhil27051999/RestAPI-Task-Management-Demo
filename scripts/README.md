## Usage Instructions

### Make Scripts Executable
```bash
chmod +x scripts/*.sh
```

### Setup Environment
```bash
# Setup complete environment
./scripts/setup-environment.sh
```

### Deploy Application
```bash
# Deploy to development
./scripts/deploy-to-k8s.sh dev

# Deploy to staging
./scripts/deploy-to-k8s.sh staging

# Deploy to production
./scripts/deploy-to-k8s.sh prod

# Rollback deployment
./scripts/deploy-to-k8s.sh prod rollback
```

### Cleanup Resources
```bash
# Cleanup application only
./scripts/cleanup.sh app

# Cleanup entire namespace
./scripts/cleanup.sh namespace

# Complete cleanup
./scripts/cleanup.sh all

# Show help
./scripts/cleanup.sh help
```

## Script Features

### setup-environment.sh
✅ **Complete Environment Setup** - Kubernetes, ingress, monitoring, ArgoCD
✅ **Prerequisite Checking** - Validates required tools
✅ **Automated Installation** - Installs all required components
✅ **Secret Management** - Creates necessary secrets
✅ **Storage Configuration** - Sets up storage classes

### deploy-to-k8s.sh
✅ **Multi-Environment Support** - Dev, staging, production deployments
✅ **Image Tag Management** - Environment-specific image tags
✅ **Health Verification** - Automated health checks
✅ **Rollback Support** - Easy rollback functionality
✅ **Access Information** - Shows URLs and useful commands

### cleanup.sh
✅ **Granular Cleanup** - Selective resource cleanup
✅ **Safety Confirmations** - Prevents accidental deletions
✅ **Complete Cleanup** - Option to remove everything
✅ **Docker Integration** - Cleans up local Docker images

These scripts provide complete automation for environment setup, deployment, and cleanup of the Task Management API project!

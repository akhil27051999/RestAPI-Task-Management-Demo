## Required GitHub Secrets

Configure these secrets in your GitHub repository settings (`Settings > Secrets and variables > Actions`):

### AWS Configuration
```
AWS_ACCESS_KEY_ID          # AWS access key for ECR and EKS
AWS_SECRET_ACCESS_KEY      # AWS secret access key
```

### Notifications (Optional)
```
SLACK_WEBHOOK_URL          # Slack webhook for deployment notifications
TEAMS_WEBHOOK_URL          # Microsoft Teams webhook URL
```

## Workflow Features

### 🧪 **Testing Stage**
- **Unit Tests**: Maven test execution with MySQL service
- **Code Coverage**: JaCoCo coverage reports uploaded to Codecov
- **Test Reports**: JUnit test results published to GitHub
- **Parallel Execution**: Tests run in parallel with security scans

### 🔒 **Security Stage**
- **Dependency Scanning**: OWASP dependency vulnerability check
- **Container Scanning**: Trivy security scan of Docker images
- **SARIF Upload**: Security results uploaded to GitHub Security tab
- **Artifact Storage**: Security reports stored as artifacts

### 🏗️ **Build Stage**
- **Maven Build**: Clean package with dependency caching
- **Docker Build**: Multi-platform image build with BuildKit
- **ECR Push**: Automatic push to Amazon ECR
- **Image Tagging**: Smart tagging based on branch and commit
- **Build Caching**: GitHub Actions cache for faster builds

### 🚀 **Deployment Stages**
- **Development**: Auto-deploy from `develop` branch
- **Staging**: Deploy from `main` branch with integration tests
- **Production**: Deploy from `main` branch with approval gates
- **Health Checks**: Comprehensive health verification
- **Rollout Verification**: Kubernetes rollout status monitoring

### 📢 **Notification Stage**
- **Slack Integration**: Success/failure notifications
- **Teams Integration**: Microsoft Teams notifications
- **Deployment Status**: Detailed deployment information
- **Quick Links**: Direct links to GitHub Actions runs

## Branch Strategy

### Development Flow
```
develop branch → Development environment
├── Automatic deployment
├── Smoke tests
└── Slack notification
```

### Production Flow
```
main branch → Staging → Production
├── Integration tests in staging
├── Manual approval for production
├── Comprehensive health checks
└── Success/failure notifications
```

## Environment Configuration

### Development
- **Cluster**: `task-management-dev-cluster`
- **Namespace**: `task-management-dev`
- **Replicas**: 1
- **Image Tag**: `develop-{commit-sha}`

### Staging
- **Cluster**: `task-management-staging-cluster`
- **Namespace**: `task-management-staging`
- **Replicas**: 2
- **Image Tag**: `main-{commit-sha}`

### Production
- **Cluster**: `task-management-prod-cluster`
- **Namespace**: `task-management`
- **Replicas**: 3
- **Image Tag**: `latest`

## Usage Examples

### Trigger Development Deployment
```bash
git checkout develop
git add .
git commit -m "feat: add new feature"
git push origin develop
# Automatically deploys to development
```

### Trigger Production Deployment
```bash
git checkout main
git merge develop
git push origin main
# Deploys to staging, then production (with approval)
```

### Manual Workflow Trigger
```bash
# Trigger workflow manually from GitHub UI
# Go to Actions tab → Select workflow → Run workflow
```

## Monitoring Workflow

### View Workflow Status
- **GitHub Actions Tab**: Real-time workflow execution
- **Slack Notifications**: Deployment status updates
- **Email Notifications**: GitHub workflow failure emails

### Debug Failed Workflows
```bash
# Check workflow logs in GitHub Actions
# Download artifacts for detailed reports
# Review security scan results in Security tab
```

This CI/CD pipeline provides complete automation from code commit to production deployment with comprehensive testing, security scanning, and monitoring capabilities!

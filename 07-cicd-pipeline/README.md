## Required GitHub Secrets

Configure these secrets in your GitHub repository settings:

### AWS Configuration
```
AWS_ACCESS_KEY_ID          # AWS access key for ECR and EKS
AWS_SECRET_ACCESS_KEY      # AWS secret key
AWS_ACCOUNT_ID            # AWS account ID for ECR repository
```

### GitOps Integration
```
GITOPS_TOKEN              # GitHub token for GitOps repository access
```

### Notifications
```
SLACK_WEBHOOK_URL         # Slack webhook for deployment notifications
```

## Pipeline Features

### 1. **Automated Testing**
- Unit tests with JUnit 5
- Integration tests with test database
- Test reporting and coverage
- Parallel test execution

### 2. **Security Scanning**
- OWASP dependency vulnerability check
- Docker image security scanning with Trivy
- SARIF report upload to GitHub Security

### 3. **Build & Push**
- Maven build with caching
- Multi-platform Docker image build
- Push to Amazon ECR
- Image tagging strategy

### 4. **GitOps Integration**
- Automatic GitOps repository update
- Image tag propagation
- Declarative deployment approach

### 5. **Multi-Environment Deployment**
- Development environment (develop branch)
- Production environment (main branch)
- Environment-specific configurations
- Smoke testing after deployment

### 6. **Notifications**
- Slack integration for deployment status
- Success/failure notifications
- Team collaboration

## Workflow Triggers

### Push Events
- **main branch**: Triggers full pipeline with production deployment
- **develop branch**: Triggers pipeline with development deployment

### Pull Request Events
- **to main**: Runs tests and security scans only
- No deployment for PR events

## Pipeline Stages

1. **Test** → Run unit and integration tests
2. **Security Scan** → Check for vulnerabilities
3. **Build** → Create and push Docker image
4. **Deploy Dev** → Deploy to development (develop branch)
5. **Deploy Prod** → Deploy to production (main branch)
6. **Notify** → Send deployment notifications

## Usage

### Setup
1. Add required secrets to GitHub repository
2. Ensure AWS ECR repository exists
3. Configure EKS clusters for dev/prod
4. Set up GitOps repository (optional)

### Deployment
- **Development**: Push to `develop` branch
- **Production**: Push to `main` branch
- **Testing**: Create pull request to `main`

This CI/CD pipeline provides complete automation from code commit to production deployment with proper testing, security scanning, and notifications.

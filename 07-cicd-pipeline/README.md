# Section 7: CI/CD Pipeline

## Overview
Complete CI/CD pipeline using GitHub Actions for Continuous Integration and ArgoCD for GitOps-based Continuous Deployment.

## Directory Structure
```
7-cicd-pipeline/
├── .github/
│   └── workflows/
│       ├── ci-pipeline.yml
│       ├── security-scan.yml
│       ├── release.yml
│       └── cleanup.yml
├── argocd/
│   ├── applications/
│   │   ├── task-management-dev.yaml
│   │   ├── task-management-staging.yaml
│   │   └── task-management-prod.yaml
│   ├── projects/
│   │   └── task-management-project.yaml
│   └── repositories/
│       └── task-management-repo.yaml
├── gitops-repo/
│   ├── environments/
│   │   ├── dev/
│   │   │   ├── kustomization.yaml
│   │   │   └── values.yaml
│   │   ├── staging/
│   │   │   ├── kustomization.yaml
│   │   │   └── values.yaml
│   │   └── prod/
│   │       ├── kustomization.yaml
│   │       └── values.yaml
│   └── base/
│       ├── kustomization.yaml
│       └── deployment.yaml
└── scripts/
    ├── setup-argocd.sh
    ├── create-secrets.sh
    └── sync-apps.sh
```

## GitHub Actions CI Pipeline

### Main CI Pipeline
```yaml
# .github/workflows/ci-pipeline.yml
name: CI Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

env:
  AWS_REGION: us-east-1
  ECR_REPOSITORY: task-management-api
  JAVA_VERSION: '17'

jobs:
  test:
    name: Run Tests
    runs-on: ubuntu-latest
    
    services:
      mysql:
        image: mysql:8.0
        env:
          MYSQL_ROOT_PASSWORD: password123
          MYSQL_DATABASE: taskdb_test
        ports:
          - 3306:3306
        options: --health-cmd="mysqladmin ping" --health-interval=10s --health-timeout=5s --health-retries=3

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Set up JDK 17
      uses: actions/setup-java@v4
      with:
        java-version: ${{ env.JAVA_VERSION }}
        distribution: 'temurin'

    - name: Cache Maven dependencies
      uses: actions/cache@v3
      with:
        path: ~/.m2
        key: ${{ runner.os }}-m2-${{ hashFiles('**/pom.xml') }}
        restore-keys: ${{ runner.os }}-m2

    - name: Run unit tests
      run: mvn clean test -Dspring.profiles.active=test

    - name: Run integration tests
      run: mvn verify -Dspring.profiles.active=test

    - name: Generate test report
      uses: dorny/test-reporter@v1
      if: success() || failure()
      with:
        name: Maven Tests
        path: target/surefire-reports/*.xml
        reporter: java-junit

    - name: Upload coverage to Codecov
      uses: codecov/codecov-action@v3
      with:
        file: target/site/jacoco/jacoco.xml

  build:
    name: Build and Push Image
    runs-on: ubuntu-latest
    needs: test
    if: github.ref == 'refs/heads/main' || github.ref == 'refs/heads/develop'

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Set up JDK 17
      uses: actions/setup-java@v4
      with:
        java-version: ${{ env.JAVA_VERSION }}
        distribution: 'temurin'

    - name: Cache Maven dependencies
      uses: actions/cache@v3
      with:
        path: ~/.m2
        key: ${{ runner.os }}-m2-${{ hashFiles('**/pom.xml') }}
        restore-keys: ${{ runner.os }}-m2

    - name: Build application
      run: mvn clean package -DskipTests

    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v4
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ${{ env.AWS_REGION }}

    - name: Login to Amazon ECR
      id: login-ecr
      uses: aws-actions/amazon-ecr-login@v2

    - name: Extract metadata
      id: meta
      uses: docker/metadata-action@v5
      with:
        images: ${{ steps.login-ecr.outputs.registry }}/${{ env.ECR_REPOSITORY }}
        tags: |
          type=ref,event=branch
          type=ref,event=pr
          type=sha,prefix={{branch}}-
          type=raw,value=latest,enable={{is_default_branch}}

    - name: Build and push Docker image
      uses: docker/build-push-action@v5
      with:
        context: .
        push: true
        tags: ${{ steps.meta.outputs.tags }}
        labels: ${{ steps.meta.outputs.labels }}
        cache-from: type=gha
        cache-to: type=gha,mode=max

    - name: Update GitOps repository
      if: github.ref == 'refs/heads/main'
      run: |
        git config --global user.name "github-actions[bot]"
        git config --global user.email "github-actions[bot]@users.noreply.github.com"
        
        # Clone GitOps repo
        git clone https://${{ secrets.GITOPS_TOKEN }}@github.com/${{ github.repository_owner }}/task-management-gitops.git
        cd task-management-gitops
        
        # Update image tag in dev environment
        IMAGE_TAG="${{ github.sha }}"
        sed -i "s|image: .*|image: ${{ steps.login-ecr.outputs.registry }}/${{ env.ECR_REPOSITORY }}:main-${IMAGE_TAG:0:7}|" environments/dev/values.yaml
        
        # Commit and push changes
        git add .
        git commit -m "Update dev image to main-${IMAGE_TAG:0:7}"
        git push origin main

  security-scan:
    name: Security Scan
    runs-on: ubuntu-latest
    needs: build
    if: github.ref == 'refs/heads/main'

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v4
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ${{ env.AWS_REGION }}

    - name: Login to Amazon ECR
      id: login-ecr
      uses: aws-actions/amazon-ecr-login@v2

    - name: Scan image with Trivy
      uses: aquasecurity/trivy-action@master
      with:
        image-ref: ${{ steps.login-ecr.outputs.registry }}/${{ env.ECR_REPOSITORY }}:main-${{ github.sha }}
        format: 'sarif'
        output: 'trivy-results.sarif'

    - name: Upload Trivy scan results
      uses: github/codeql-action/upload-sarif@v2
      with:
        sarif_file: 'trivy-results.sarif'
```

### Security Scan Workflow
```yaml
# .github/workflows/security-scan.yml
name: Security Scan

on:
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM
  workflow_dispatch:

jobs:
  dependency-scan:
    name: Dependency Vulnerability Scan
    runs-on: ubuntu-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Set up JDK 17
      uses: actions/setup-java@v4
      with:
        java-version: '17'
        distribution: 'temurin'

    - name: Run OWASP Dependency Check
      run: |
        mvn org.owasp:dependency-check-maven:check
        
    - name: Upload dependency check results
      uses: actions/upload-artifact@v3
      with:
        name: dependency-check-report
        path: target/dependency-check-report.html

  code-scan:
    name: Static Code Analysis
    runs-on: ubuntu-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Set up JDK 17
      uses: actions/setup-java@v4
      with:
        java-version: '17'
        distribution: 'temurin'

    - name: Cache SonarCloud packages
      uses: actions/cache@v3
      with:
        path: ~/.sonar/cache
        key: ${{ runner.os }}-sonar
        restore-keys: ${{ runner.os }}-sonar

    - name: Run SonarCloud analysis
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
      run: |
        mvn clean verify sonar:sonar \
          -Dsonar.projectKey=${{ github.repository_owner }}_task-management-api \
          -Dsonar.organization=${{ github.repository_owner }} \
          -Dsonar.host.url=https://sonarcloud.io
```

### Release Workflow
```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    tags:
      - 'v*'

env:
  AWS_REGION: us-east-1
  ECR_REPOSITORY: task-management-api

jobs:
  release:
    name: Create Release
    runs-on: ubuntu-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Set up JDK 17
      uses: actions/setup-java@v4
      with:
        java-version: '17'
        distribution: 'temurin'

    - name: Build application
      run: mvn clean package -DskipTests

    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v4
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ${{ env.AWS_REGION }}

    - name: Login to Amazon ECR
      id: login-ecr
      uses: aws-actions/amazon-ecr-login@v2

    - name: Build and push release image
      run: |
        IMAGE_TAG=${GITHUB_REF#refs/tags/}
        docker build -t ${{ steps.login-ecr.outputs.registry }}/${{ env.ECR_REPOSITORY }}:$IMAGE_TAG .
        docker push ${{ steps.login-ecr.outputs.registry }}/${{ env.ECR_REPOSITORY }}:$IMAGE_TAG

    - name: Create GitHub Release
      uses: actions/create-release@v1
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      with:
        tag_name: ${{ github.ref }}
        release_name: Release ${{ github.ref }}
        draft: false
        prerelease: false

    - name: Update production GitOps
      run: |
        git config --global user.name "github-actions[bot]"
        git config --global user.email "github-actions[bot]@users.noreply.github.com"
        
        git clone https://${{ secrets.GITOPS_TOKEN }}@github.com/${{ github.repository_owner }}/task-management-gitops.git
        cd task-management-gitops
        
        IMAGE_TAG=${GITHUB_REF#refs/tags/}
        sed -i "s|image: .*|image: ${{ steps.login-ecr.outputs.registry }}/${{ env.ECR_REPOSITORY }}:$IMAGE_TAG|" environments/prod/values.yaml
        
        git add .
        git commit -m "Release $IMAGE_TAG to production"
        git push origin main
```

## ArgoCD Configuration

### ArgoCD Project
```yaml
# argocd/projects/task-management-project.yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: task-management
  namespace: argocd
spec:
  description: Task Management API Project
  
  sourceRepos:
  - 'https://github.com/your-org/task-management-gitops.git'
  
  destinations:
  - namespace: task-management-dev
    server: https://kubernetes.default.svc
  - namespace: task-management-staging
    server: https://kubernetes.default.svc
  - namespace: task-management-prod
    server: https://kubernetes.default.svc
  
  clusterResourceWhitelist:
  - group: ''
    kind: Namespace
  - group: 'networking.k8s.io'
    kind: Ingress
  
  namespaceResourceWhitelist:
  - group: ''
    kind: ConfigMap
  - group: ''
    kind: Secret
  - group: ''
    kind: Service
  - group: 'apps'
    kind: Deployment
  - group: 'autoscaling'
    kind: HorizontalPodAutoscaler
  
  roles:
  - name: admin
    description: Admin access to task management project
    policies:
    - p, proj:task-management:admin, applications, *, task-management/*, allow
    - p, proj:task-management:admin, repositories, *, *, allow
    groups:
    - task-management-admins
  
  - name: developer
    description: Developer access to dev environment
    policies:
    - p, proj:task-management:developer, applications, get, task-management/task-management-dev, allow
    - p, proj:task-management:developer, applications, sync, task-management/task-management-dev, allow
    groups:
    - task-management-developers
```

### Development Application
```yaml
# argocd/applications/task-management-dev.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: task-management-dev
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: task-management
  
  source:
    repoURL: https://github.com/your-org/task-management-gitops.git
    targetRevision: HEAD
    path: environments/dev
  
  destination:
    server: https://kubernetes.default.svc
    namespace: task-management-dev
  
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
      allowEmpty: false
    syncOptions:
    - CreateNamespace=true
    - PrunePropagationPolicy=foreground
    - PruneLast=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
  
  revisionHistoryLimit: 10
  
  ignoreDifferences:
  - group: apps
    kind: Deployment
    jsonPointers:
    - /spec/replicas
```

### Staging Application
```yaml
# argocd/applications/task-management-staging.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: task-management-staging
  namespace: argocd
spec:
  project: task-management
  
  source:
    repoURL: https://github.com/your-org/task-management-gitops.git
    targetRevision: HEAD
    path: environments/staging
  
  destination:
    server: https://kubernetes.default.svc
    namespace: task-management-staging
  
  syncPolicy:
    syncOptions:
    - CreateNamespace=true
    - PrunePropagationPolicy=foreground
    retry:
      limit: 3
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 2m
```

### Production Application
```yaml
# argocd/applications/task-management-prod.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: task-management-prod
  namespace: argocd
spec:
  project: task-management
  
  source:
    repoURL: https://github.com/your-org/task-management-gitops.git
    targetRevision: HEAD
    path: environments/prod
  
  destination:
    server: https://kubernetes.default.svc
    namespace: task-management-prod
  
  syncPolicy:
    syncOptions:
    - CreateNamespace=true
    - PrunePropagationPolicy=foreground
    retry:
      limit: 2
      backoff:
        duration: 10s
        factor: 2
        maxDuration: 5m
```

## GitOps Repository Structure

### Base Kustomization
```yaml
# gitops-repo/base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml
  - service.yaml
  - configmap.yaml
  - secret.yaml
  - hpa.yaml
  - ingress.yaml

commonLabels:
  app.kubernetes.io/name: task-management-api
  app.kubernetes.io/part-of: task-management-system
```

### Development Environment
```yaml
# gitops-repo/environments/dev/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: task-management-dev

resources:
  - ../../base

namePrefix: dev-

commonLabels:
  environment: development

patchesStrategicMerge:
  - values.yaml

images:
  - name: task-management-api
    newName: <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/task-management-api
    newTag: main-abc1234
```

```yaml
# gitops-repo/environments/dev/values.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: task-management-api
spec:
  replicas: 1
  template:
    spec:
      containers:
      - name: task-management-api
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "250m"
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "dev"
        - name: LOGGING_LEVEL_ROOT
          value: "DEBUG"
```

### Production Environment
```yaml
# gitops-repo/environments/prod/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: task-management-prod

resources:
  - ../../base

namePrefix: prod-

commonLabels:
  environment: production

patchesStrategicMerge:
  - values.yaml

images:
  - name: task-management-api
    newName: <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/task-management-api
    newTag: v1.0.0
```

```yaml
# gitops-repo/environments/prod/values.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: task-management-api
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: task-management-api
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "prod"
        - name: LOGGING_LEVEL_ROOT
          value: "WARN"
```

## Setup Scripts

### ArgoCD Installation
```bash
#!/bin/bash
# scripts/setup-argocd.sh

set -e

NAMESPACE="argocd"
VERSION="v2.8.4"

echo "🚀 Installing ArgoCD..."

# Create namespace
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Install ArgoCD
kubectl apply -n $NAMESPACE -f https://raw.githubusercontent.com/argoproj/argo-cd/$VERSION/manifests/install.yaml

# Wait for ArgoCD to be ready
echo "⏳ Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n $NAMESPACE

# Get initial admin password
echo "🔑 ArgoCD Admin Password:"
kubectl -n $NAMESPACE get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo ""

# Port forward for access
echo "🌐 Access ArgoCD at: https://localhost:8080"
echo "Username: admin"
kubectl port-forward svc/argocd-server -n $NAMESPACE 8080:443 &

echo "✅ ArgoCD installation completed!"
```

### Create Secrets Script
```bash
#!/bin/bash
# scripts/create-secrets.sh

set -e

echo "🔐 Creating ArgoCD secrets..."

# Repository secret
kubectl create secret generic repo-secret \
  --from-literal=type=git \
  --from-literal=url=https://github.com/your-org/task-management-gitops.git \
  --from-literal=username=your-username \
  --from-literal=password=$GITHUB_TOKEN \
  -n argocd

kubectl label secret repo-secret argocd.argoproj.io/secret-type=repository -n argocd

# ECR secret for image pulling
kubectl create secret docker-registry ecr-secret \
  --docker-server=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region $AWS_REGION) \
  -n task-management-dev

kubectl create secret docker-registry ecr-secret \
  --docker-server=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region $AWS_REGION) \
  -n task-management-staging

kubectl create secret docker-registry ecr-secret \
  --docker-server=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region $AWS_REGION) \
  -n task-management-prod

echo "✅ Secrets created successfully!"
```

### Sync Applications Script
```bash
#!/bin/bash
# scripts/sync-apps.sh

set -e

ARGOCD_SERVER="localhost:8080"
ARGOCD_USERNAME="admin"
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo "🔄 Syncing ArgoCD applications..."

# Login to ArgoCD CLI
argocd login $ARGOCD_SERVER --username $ARGOCD_USERNAME --password $ARGOCD_PASSWORD --insecure

# Apply ArgoCD configurations
kubectl apply -f argocd/projects/
kubectl apply -f argocd/applications/

# Sync applications
argocd app sync task-management-dev
argocd app sync task-management-staging

echo "✅ Applications synced successfully!"

# Show application status
argocd app list
```

## Monitoring and Notifications

### Slack Notifications
```yaml
# Add to GitHub Actions workflow
- name: Notify Slack on Success
  if: success()
  uses: 8398a7/action-slack@v3
  with:
    status: success
    channel: '#deployments'
    text: '✅ Task Management API deployed successfully to ${{ github.ref }}'
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}

- name: Notify Slack on Failure
  if: failure()
  uses: 8398a7/action-slack@v3
  with:
    status: failure
    channel: '#deployments'
    text: '❌ Task Management API deployment failed on ${{ github.ref }}'
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```

### ArgoCD Notifications
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-notifications-cm
  namespace: argocd
data:
  service.slack: |
    token: $slack-token
  template.app-deployed: |
    message: |
      {{if eq .serviceType "slack"}}:white_check_mark:{{end}} Application {{.app.metadata.name}} is now running new version.
  template.app-health-degraded: |
    message: |
      {{if eq .serviceType "slack"}}:exclamation:{{end}} Application {{.app.metadata.name}} has degraded health.
  trigger.on-deployed: |
    - when: app.status.operationState.phase in ['Succeeded'] and app.status.health.status == 'Healthy'
      send: [app-deployed]
  trigger.on-health-degraded: |
    - when: app.status.health.status == 'Degraded'
      send: [app-health-degraded]
  subscriptions: |
    - recipients:
      - slack:deployments
      triggers:
      - on-deployed
      - on-health-degraded
```

## Security Best Practices

### GitHub Secrets Required
```bash
# Repository secrets to configure:
AWS_ACCESS_KEY_ID          # AWS access key for ECR
AWS_SECRET_ACCESS_KEY      # AWS secret key for ECR
GITOPS_TOKEN              # GitHub token for GitOps repo
SONAR_TOKEN               # SonarCloud token
SLACK_WEBHOOK_URL         # Slack webhook for notifications
```

### RBAC Configuration
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: argocd-application-controller
  namespace: argocd
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: argocd-application-controller
rules:
- apiGroups: [""]
  resources: ["*"]
  verbs: ["*"]
- apiGroups: ["apps"]
  resources: ["*"]
  verbs: ["*"]
- apiGroups: ["networking.k8s.io"]
  resources: ["*"]
  verbs: ["*"]
```

## Troubleshooting

### Common Issues

1. **ArgoCD Sync Failures**
   ```bash
   argocd app get task-management-dev
   argocd app logs task-management-dev
   ```

2. **GitHub Actions Failures**
   ```bash
   # Check workflow logs in GitHub Actions tab
   # Verify secrets are properly configured
   ```

3. **Image Pull Errors**
   ```bash
   # Update ECR credentials
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account>.dkr.ecr.us-east-1.amazonaws.com
   ```

## Next Steps

After completing this section, you'll have:
- ✅ Complete CI/CD pipeline with GitHub Actions
- ✅ GitOps deployment with ArgoCD
- ✅ Multi-environment deployment strategy
- ✅ Security scanning and quality gates
- ✅ Automated notifications and monitoring
- ✅ Production-ready deployment workflows

**Ready for Section 8: Infrastructure as Code** - Complete Terraform configurations for AWS infrastructure automation!

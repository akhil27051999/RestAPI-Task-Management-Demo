# 7-CI/CD Pipeline Files

## github-actions/ci-cd-pipeline.yml
```yaml
name: CI/CD Pipeline

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
    name: Test
    runs-on: ubuntu-latest
    
    services:
      mysql:
        image: mysql:8.0
        env:
          MYSQL_ROOT_PASSWORD: testpass
          MYSQL_DATABASE: taskdb_test
        ports:
          - 3306:3306
        options: --health-cmd="mysqladmin ping" --health-interval=10s --health-timeout=5s --health-retries=3

    steps:
    - name: Checkout
      uses: actions/checkout@v4

    - name: Setup JDK
      uses: actions/setup-java@v4
      with:
        java-version: ${{ env.JAVA_VERSION }}
        distribution: 'temurin'

    - name: Cache Maven
      uses: actions/cache@v3
      with:
        path: ~/.m2
        key: ${{ runner.os }}-m2-${{ hashFiles('**/pom.xml') }}

    - name: Run Tests
      run: mvn clean test

    - name: Generate Coverage
      run: mvn jacoco:report

    - name: Upload Coverage
      uses: codecov/codecov-action@v3
      with:
        file: target/site/jacoco/jacoco.xml

  security:
    name: Security Scan
    runs-on: ubuntu-latest
    needs: test

    steps:
    - name: Checkout
      uses: actions/checkout@v4

    - name: Setup JDK
      uses: actions/setup-java@v4
      with:
        java-version: ${{ env.JAVA_VERSION }}
        distribution: 'temurin'

    - name: OWASP Dependency Check
      run: mvn org.owasp:dependency-check-maven:check

    - name: Upload Security Report
      uses: actions/upload-artifact@v3
      with:
        name: security-report
        path: target/dependency-check-report.html

  build:
    name: Build & Push
    runs-on: ubuntu-latest
    needs: [test, security]
    if: github.ref == 'refs/heads/main' || github.ref == 'refs/heads/develop'

    steps:
    - name: Checkout
      uses: actions/checkout@v4

    - name: Setup JDK
      uses: actions/setup-java@v4
      with:
        java-version: ${{ env.JAVA_VERSION }}
        distribution: 'temurin'

    - name: Build Application
      run: mvn clean package -DskipTests

    - name: Configure AWS
      uses: aws-actions/configure-aws-credentials@v4
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ${{ env.AWS_REGION }}

    - name: Login to ECR
      id: login-ecr
      uses: aws-actions/amazon-ecr-login@v2

    - name: Build & Push Image
      run: |
        IMAGE_TAG=${GITHUB_SHA::7}
        docker build -t ${{ steps.login-ecr.outputs.registry }}/${{ env.ECR_REPOSITORY }}:$IMAGE_TAG .
        docker push ${{ steps.login-ecr.outputs.registry }}/${{ env.ECR_REPOSITORY }}:$IMAGE_TAG
        
        if [ "${{ github.ref }}" = "refs/heads/main" ]; then
          docker tag ${{ steps.login-ecr.outputs.registry }}/${{ env.ECR_REPOSITORY }}:$IMAGE_TAG ${{ steps.login-ecr.outputs.registry }}/${{ env.ECR_REPOSITORY }}:latest
          docker push ${{ steps.login-ecr.outputs.registry }}/${{ env.ECR_REPOSITORY }}:latest
        fi

    - name: Update GitOps Repo
      run: |
        git config --global user.name "github-actions"
        git config --global user.email "actions@github.com"
        
        git clone https://${{ secrets.GITOPS_TOKEN }}@github.com/${{ github.repository_owner }}/task-management-gitops.git
        cd task-management-gitops
        
        IMAGE_TAG=${GITHUB_SHA::7}
        ENV="dev"
        if [ "${{ github.ref }}" = "refs/heads/main" ]; then
          ENV="production"
        fi
        
        sed -i "s|image: .*|image: ${{ steps.login-ecr.outputs.registry }}/${{ env.ECR_REPOSITORY }}:$IMAGE_TAG|" argocd/config-repo/$ENV/deployment.yaml
        
        git add .
        git commit -m "Update $ENV image to $IMAGE_TAG"
        git push origin main

  deploy-dev:
    name: Deploy Dev
    runs-on: ubuntu-latest
    needs: build
    if: github.ref == 'refs/heads/develop'
    environment: development

    steps:
    - name: Deploy to Dev
      run: |
        echo "Deploying to development environment"
        # ArgoCD will automatically sync the changes

  deploy-prod:
    name: Deploy Production
    runs-on: ubuntu-latest
    needs: build
    if: github.ref == 'refs/heads/main'
    environment: production

    steps:
    - name: Deploy to Production
      run: |
        echo "Deploying to production environment"
        # ArgoCD will automatically sync the changes

  notify:
    name: Notify
    runs-on: ubuntu-latest
    needs: [deploy-dev, deploy-prod]
    if: always()

    steps:
    - name: Slack Notification
      uses: 8398a7/action-slack@v3
      with:
        status: ${{ job.status }}
        channel: '#deployments'
        text: 'Task Management API deployment ${{ job.status }}'
      env:
        SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```

## jenkins/Jenkinsfile
```groovy
pipeline {
    agent any
    
    environment {
        AWS_REGION = 'us-east-1'
        ECR_REPOSITORY = 'task-management-api'
        JAVA_VERSION = '17'
        MAVEN_OPTS = '-Dmaven.repo.local=.m2/repository'
    }
    
    tools {
        maven 'Maven-3.9'
        jdk 'JDK-17'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.GIT_COMMIT_SHORT = sh(
                        script: "git rev-parse --short HEAD",
                        returnStdout: true
                    ).trim()
                }
            }
        }
        
        stage('Test') {
            parallel {
                stage('Unit Tests') {
                    steps {
                        sh 'mvn clean test'
                    }
                    post {
                        always {
                            publishTestResults testResultsPattern: 'target/surefire-reports/*.xml'
                            publishCoverage adapters: [
                                jacocoAdapter('target/site/jacoco/jacoco.xml')
                            ]
                        }
                    }
                }
                
                stage('Security Scan') {
                    steps {
                        sh 'mvn org.owasp:dependency-check-maven:check'
                    }
                    post {
                        always {
                            publishHTML([
                                allowMissing: false,
                                alwaysLinkToLastBuild: true,
                                keepAll: true,
                                reportDir: 'target',
                                reportFiles: 'dependency-check-report.html',
                                reportName: 'OWASP Dependency Check'
                            ])
                        }
                    }
                }
            }
        }
        
        stage('Build') {
            steps {
                sh 'mvn clean package -DskipTests'
                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            }
        }
        
        stage('Docker Build & Push') {
            when {
                anyOf {
                    branch 'main'
                    branch 'develop'
                }
            }
            steps {
                script {
                    withAWS(region: env.AWS_REGION, credentials: 'aws-credentials') {
                        def ecrLogin = sh(
                            script: "aws ecr get-login-password --region ${env.AWS_REGION}",
                            returnStdout: true
                        ).trim()
                        
                        sh "echo ${ecrLogin} | docker login --username AWS --password-stdin ${env.AWS_ACCOUNT_ID}.dkr.ecr.${env.AWS_REGION}.amazonaws.com"
                        
                        def imageTag = env.GIT_COMMIT_SHORT
                        def imageName = "${env.AWS_ACCOUNT_ID}.dkr.ecr.${env.AWS_REGION}.amazonaws.com/${env.ECR_REPOSITORY}:${imageTag}"
                        
                        sh "docker build -t ${imageName} ."
                        sh "docker push ${imageName}"
                        
                        if (env.BRANCH_NAME == 'main') {
                            def latestImage = "${env.AWS_ACCOUNT_ID}.dkr.ecr.${env.AWS_REGION}.amazonaws.com/${env.ECR_REPOSITORY}:latest"
                            sh "docker tag ${imageName} ${latestImage}"
                            sh "docker push ${latestImage}"
                        }
                    }
                }
            }
        }
        
        stage('Update GitOps') {
            when {
                anyOf {
                    branch 'main'
                    branch 'develop'
                }
            }
            steps {
                script {
                    withCredentials([string(credentialsId: 'gitops-token', variable: 'GITOPS_TOKEN')]) {
                        sh '''
                            git config --global user.name "Jenkins"
                            git config --global user.email "jenkins@company.com"
                            
                            git clone https://${GITOPS_TOKEN}@github.com/${GITHUB_ORG}/task-management-gitops.git
                            cd task-management-gitops
                            
                            ENV="dev"
                            if [ "${BRANCH_NAME}" = "main" ]; then
                                ENV="production"
                            fi
                            
                            sed -i "s|image: .*|image: ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}:${GIT_COMMIT_SHORT}|" argocd/config-repo/${ENV}/deployment.yaml
                            
                            git add .
                            git commit -m "Update ${ENV} image to ${GIT_COMMIT_SHORT}"
                            git push origin main
                        '''
                    }
                }
            }
        }
        
        stage('Deploy') {
            parallel {
                stage('Deploy Dev') {
                    when {
                        branch 'develop'
                    }
                    steps {
                        echo 'Deploying to development environment via ArgoCD'
                        // ArgoCD will automatically sync
                    }
                }
                
                stage('Deploy Production') {
                    when {
                        branch 'main'
                    }
                    steps {
                        input message: 'Deploy to production?', ok: 'Deploy'
                        echo 'Deploying to production environment via ArgoCD'
                        // ArgoCD will automatically sync
                    }
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        success {
            slackSend(
                channel: '#deployments',
                color: 'good',
                message: "✅ Task Management API pipeline succeeded for ${env.BRANCH_NAME}"
            )
        }
        failure {
            slackSend(
                channel: '#deployments',
                color: 'danger',
                message: "❌ Task Management API pipeline failed for ${env.BRANCH_NAME}"
            )
        }
    }
}
```

## argocd/application.yaml
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: task-management-api
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  
  source:
    repoURL: https://github.com/your-org/task-management-gitops.git
    targetRevision: HEAD
    path: argocd/config-repo/production
  
  destination:
    server: https://kubernetes.default.svc
    namespace: task-management
  
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

---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: task-management-api-dev
  namespace: argocd
spec:
  project: default
  
  source:
    repoURL: https://github.com/your-org/task-management-gitops.git
    targetRevision: HEAD
    path: argocd/config-repo/dev
  
  destination:
    server: https://kubernetes.default.svc
    namespace: task-management-dev
  
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true

---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: task-management-api-staging
  namespace: argocd
spec:
  project: default
  
  source:
    repoURL: https://github.com/your-org/task-management-gitops.git
    targetRevision: HEAD
    path: argocd/config-repo/staging
  
  destination:
    server: https://kubernetes.default.svc
    namespace: task-management-staging
  
  syncPolicy:
    syncOptions:
    - CreateNamespace=true
```

## argocd/config-repo/dev/deployment.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: task-management-api
  namespace: task-management-dev
  labels:
    app: task-management-api
    environment: dev
spec:
  replicas: 1
  selector:
    matchLabels:
      app: task-management-api
  template:
    metadata:
      labels:
        app: task-management-api
        environment: dev
    spec:
      containers:
      - name: task-management-api
        image: 123456789012.dkr.ecr.us-east-1.amazonaws.com/task-management-api:latest
        ports:
        - containerPort: 8080
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "dev"
        - name: SPRING_DATASOURCE_URL
          value: "jdbc:mysql://mysql-service:3306/taskdb_dev"
        - name: SPRING_DATASOURCE_USERNAME
          valueFrom:
            secretKeyRef:
              name: task-api-secret
              key: mysql-username
        - name: SPRING_DATASOURCE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: task-api-secret
              key: mysql-password
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "250m"
        livenessProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          initialDelaySeconds: 60
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /actuator/health/readiness
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
```

## argocd/config-repo/dev/service.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  name: task-management-service
  namespace: task-management-dev
  labels:
    app: task-management-api
    environment: dev
spec:
  selector:
    app: task-management-api
  ports:
  - name: http
    port: 80
    targetPort: 8080
  type: ClusterIP
```

## argocd/config-repo/dev/kustomization.yaml
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: task-management-dev

resources:
  - deployment.yaml
  - service.yaml

commonLabels:
  environment: dev
  managed-by: argocd

images:
  - name: task-management-api
    newName: 123456789012.dkr.ecr.us-east-1.amazonaws.com/task-management-api
    newTag: latest
```

## argocd/config-repo/staging/deployment.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: task-management-api
  namespace: task-management-staging
  labels:
    app: task-management-api
    environment: staging
spec:
  replicas: 2
  selector:
    matchLabels:
      app: task-management-api
  template:
    metadata:
      labels:
        app: task-management-api
        environment: staging
    spec:
      containers:
      - name: task-management-api
        image: 123456789012.dkr.ecr.us-east-1.amazonaws.com/task-management-api:latest
        ports:
        - containerPort: 8080
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "staging"
        - name: SPRING_DATASOURCE_URL
          value: "jdbc:mysql://mysql-service:3306/taskdb_staging"
        - name: SPRING_DATASOURCE_USERNAME
          valueFrom:
            secretKeyRef:
              name: task-api-secret
              key: mysql-username
        - name: SPRING_DATASOURCE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: task-api-secret
              key: mysql-password
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          initialDelaySeconds: 60
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /actuator/health/readiness
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
```

## argocd/config-repo/staging/service.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  name: task-management-service
  namespace: task-management-staging
  labels:
    app: task-management-api
    environment: staging
spec:
  selector:
    app: task-management-api
  ports:
  - name: http
    port: 80
    targetPort: 8080
  type: ClusterIP
```

## argocd/config-repo/staging/kustomization.yaml
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: task-management-staging

resources:
  - deployment.yaml
  - service.yaml

commonLabels:
  environment: staging
  managed-by: argocd

images:
  - name: task-management-api
    newName: 123456789012.dkr.ecr.us-east-1.amazonaws.com/task-management-api
    newTag: latest
```

## argocd/config-repo/production/deployment.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: task-management-api
  namespace: task-management
  labels:
    app: task-management-api
    environment: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: task-management-api
  template:
    metadata:
      labels:
        app: task-management-api
        environment: production
    spec:
      containers:
      - name: task-management-api
        image: 123456789012.dkr.ecr.us-east-1.amazonaws.com/task-management-api:latest
        ports:
        - containerPort: 8080
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "prod"
        - name: SPRING_DATASOURCE_URL
          value: "jdbc:mysql://mysql-service:3306/taskdb"
        - name: SPRING_DATASOURCE_USERNAME
          valueFrom:
            secretKeyRef:
              name: task-api-secret
              key: mysql-username
        - name: SPRING_DATASOURCE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: task-api-secret
              key: mysql-password
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          initialDelaySeconds: 90
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /actuator/health/readiness
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        startupProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
          failureThreshold: 12
```

## argocd/config-repo/production/service.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  name: task-management-service
  namespace: task-management
  labels:
    app: task-management-api
    environment: production
spec:
  selector:
    app: task-management-api
  ports:
  - name: http
    port: 80
    targetPort: 8080
  type: ClusterIP
```

## argocd/config-repo/production/hpa.yaml
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: task-management-hpa
  namespace: task-management
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: task-management-api
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

## argocd/config-repo/production/kustomization.yaml
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: task-management

resources:
  - deployment.yaml
  - service.yaml
  - hpa.yaml

commonLabels:
  environment: production
  managed-by: argocd

images:
  - name: task-management-api
    newName: 123456789012.dkr.ecr.us-east-1.amazonaws.com/task-management-api
    newTag: latest
```

## Setup Instructions

### GitHub Actions Setup
1. Add repository secrets:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `GITOPS_TOKEN`
   - `SLACK_WEBHOOK_URL`

### Jenkins Setup
1. Install plugins:
   - AWS Steps
   - Docker Pipeline
   - Slack Notification
2. Configure credentials:
   - `aws-credentials`
   - `gitops-token`
3. Set environment variables:
   - `AWS_ACCOUNT_ID`
   - `GITHUB_ORG`

### ArgoCD Setup
1. Install ArgoCD in cluster
2. Apply application manifests
3. Configure repository access
4. Set up automatic sync policies

This CI/CD setup provides complete automation from code commit to production deployment with proper testing, security scanning, and GitOps practices.

## Overview
Complete deployment guide for the Task Management API across different environments.

## Prerequisites
- Docker 20.10+
- Kubernetes 1.20+
- kubectl configured
- Helm 3.0+ (optional)
- AWS CLI (for AWS deployments)

## Local Development

### Using Docker Compose
```bash
# Clone repository
git clone https://github.com/your-org/task-management-api.git
cd task-management-api

# Start services
docker-compose up -d

# Verify deployment
curl http://localhost:8080/actuator/health
```

### Using Maven
```bash
# Prerequisites
export DB_USERNAME=root
export DB_PASSWORD=password123

# Start MySQL
docker run -d --name mysql \
  -e MYSQL_ROOT_PASSWORD=password123 \
  -e MYSQL_DATABASE=taskdb \
  -p 3306:3306 mysql:8.0

# Build and run
mvn clean package
mvn spring-boot:run
```

## Kubernetes Deployment

### Quick Deployment
```bash
# Apply all manifests
kubectl apply -f k8s/

# Check deployment status
kubectl get pods -n task-management
kubectl get services -n task-management
```

### Step-by-Step Deployment

#### 1. Create Namespace
```bash
kubectl apply -f k8s/namespace.yaml
```

#### 2. Deploy Secrets and ConfigMaps
```bash
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/configmap.yaml
```

#### 3. Deploy Database
```bash
kubectl apply -f k8s/mysql-deployment.yaml
kubectl apply -f k8s/mysql-service.yaml

# Wait for MySQL to be ready
kubectl wait --for=condition=ready pod -l app=mysql -n task-management --timeout=300s
```

#### 4. Deploy Application
```bash
kubectl apply -f k8s/task-api-deployment.yaml
kubectl apply -f k8s/task-api-service.yaml

# Wait for application to be ready
kubectl wait --for=condition=ready pod -l app=task-api -n task-management --timeout=300s
```

#### 5. Configure Ingress and Scaling
```bash
kubectl apply -f k8s/ingress.yaml
kubectl apply -f k8s/hpa.yaml
kubectl apply -f k8s/pdb.yaml
```

### Verification
```bash
# Check all resources
kubectl get all -n task-management

# Test API
kubectl port-forward svc/task-api-service 8080:80 -n task-management
curl http://localhost:8080/api/tasks
```

## AWS EKS Deployment

### Infrastructure Setup
```bash
# Create EKS cluster using Terraform
cd terraform/environments/prod
terraform init
terraform plan
terraform apply

# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name task-management-prod-cluster
```

### Application Deployment
```bash
# Update image repository in manifests
sed -i 's|<AWS_ACCOUNT_ID>|123456789012|g' k8s/task-api-deployment.yaml
sed -i 's|<REGION>|us-east-1|g' k8s/task-api-deployment.yaml

# Deploy application
kubectl apply -f k8s/

# Check ingress
kubectl get ingress -n task-management
```

## CI/CD Deployment

### GitHub Actions
```bash
# Set up repository secrets
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
GITOPS_TOKEN

# Push to trigger deployment
git push origin main  # Deploys to production
git push origin develop  # Deploys to development
```

### ArgoCD GitOps
```bash
# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Apply applications
kubectl apply -f argocd/application.yaml

# Access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

## Environment-Specific Configurations

### Development
- 1 replica
- Minimal resources (256Mi RAM, 100m CPU)
- Debug logging enabled
- H2 in-memory database (optional)

### Staging
- 2 replicas
- Medium resources (512Mi RAM, 250m CPU)
- Production-like configuration
- Shared MySQL instance

### Production
- 3+ replicas
- Full resources (1Gi RAM, 500m CPU)
- HPA enabled (2-10 replicas)
- Dedicated RDS instance
- SSL/TLS enabled
- Monitoring and alerting

## Database Migration

### Initial Setup
```sql
CREATE DATABASE taskdb;
CREATE USER 'taskuser'@'%' IDENTIFIED BY 'secure_password';
GRANT ALL PRIVILEGES ON taskdb.* TO 'taskuser'@'%';
FLUSH PRIVILEGES;
```

### Schema Updates
```bash
# Using Flyway (recommended for production)
mvn flyway:migrate

# Using Hibernate (development only)
# Set spring.jpa.hibernate.ddl-auto=update
```

## SSL/TLS Configuration

### cert-manager Setup
```bash
# Install cert-manager
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.12.0/cert-manager.yaml

# Create ClusterIssuer
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@taskmanagement.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
```

## Monitoring Deployment

### Prometheus Stack
```bash
# Deploy monitoring
kubectl apply -f monitoring/prometheus/
kubectl apply -f monitoring/grafana/

# Access Grafana
kubectl port-forward svc/grafana-service 3000:3000 -n monitoring
# Login: admin/admin123
```

### ELK Stack
```bash
# Deploy ELK
kubectl apply -f monitoring/elk-stack/

# Access Kibana
kubectl port-forward svc/kibana 5601:5601 -n monitoring
```

## Backup and Recovery

### Database Backup
```bash
# Create backup
kubectl exec -it deployment/mysql -n task-management -- \
  mysqldump -u root -p taskdb > backup-$(date +%Y%m%d).sql

# Restore backup
kubectl exec -i deployment/mysql -n task-management -- \
  mysql -u root -p taskdb < backup-20240115.sql
```

### Configuration Backup
```bash
# Backup Kubernetes resources
kubectl get all -n task-management -o yaml > k8s-backup.yaml

# Backup secrets (be careful with sensitive data)
kubectl get secrets -n task-management -o yaml > secrets-backup.yaml
```

## Scaling

### Manual Scaling
```bash
# Scale application
kubectl scale deployment task-api --replicas=5 -n task-management

# Scale database (if using StatefulSet)
kubectl scale statefulset mysql --replicas=3 -n task-management
```

### Auto Scaling
```bash
# Check HPA status
kubectl get hpa -n task-management

# Update HPA configuration
kubectl patch hpa task-api-hpa -n task-management -p '{"spec":{"maxReplicas":20}}'
```

## Rollback

### Kubernetes Rollback
```bash
# Check rollout history
kubectl rollout history deployment/task-api -n task-management

# Rollback to previous version
kubectl rollout undo deployment/task-api -n task-management

# Rollback to specific revision
kubectl rollout undo deployment/task-api --to-revision=2 -n task-management
```

### ArgoCD Rollback
```bash
# Using ArgoCD CLI
argocd app rollback task-management-api --revision 2

# Using ArgoCD UI
# Navigate to application -> History and Rollback -> Select revision
```

## Performance Tuning

### JVM Tuning
```yaml
env:
- name: JAVA_OPTS
  value: "-XX:+UseG1GC -XX:MaxRAMPercentage=75.0 -XX:+UseContainerSupport"
```

### Database Tuning
```yaml
# MySQL configuration
env:
- name: MYSQL_INNODB_BUFFER_POOL_SIZE
  value: "1G"
- name: MYSQL_MAX_CONNECTIONS
  value: "200"
```

## Security Hardening

### Pod Security
```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000
  capabilities:
    drop:
    - ALL
```

### Network Policies
```bash
kubectl apply -f k8s/network-policy.yaml
```

## Troubleshooting Commands

### Check Pod Status
```bash
kubectl get pods -n task-management
kubectl describe pod <pod-name> -n task-management
kubectl logs -f <pod-name> -n task-management
```

### Check Services
```bash
kubectl get svc -n task-management
kubectl describe svc task-api-service -n task-management
```

### Check Ingress
```bash
kubectl get ingress -n task-management
kubectl describe ingress task-api-ingress -n task-management
```

This deployment guide covers all aspects of deploying the Task Management API from local development to production environments.
```

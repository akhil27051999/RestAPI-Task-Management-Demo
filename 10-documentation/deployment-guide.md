# Deployment Guide

## Overview
Complete deployment guide for Task Management System with backend API, frontend dashboard, database, and monitoring stack.

## Architecture
```
Internet → Ingress → Frontend (Nginx) → Backend (Spring Boot) → MySQL
                  ↓
              Monitoring (Prometheus/Grafana)
```

## Prerequisites
- Docker & Docker Compose
- Kubernetes cluster (for production)
- kubectl configured
- Docker registry access

## Local Development

### Using Docker Compose
```bash
# Clone repository
git clone <repository-url>
cd task-management-api

# Start all services
cd 5-containerization
docker-compose up -d

# Verify services
docker-compose ps
```

### Access URLs
- Frontend: http://localhost:3001
- Backend API: http://localhost:8080
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000 (admin/admin123)
- MySQL: localhost:3306

## Production Deployment

### 1. Build and Push Images
```bash
# Build backend
cd 2-source-code
docker build -t your-registry/task-management-api:v1.0 .
docker push your-registry/task-management-api:v1.0

# Build frontend
cd ../3-frontend
docker build -t your-registry/task-management-frontend:v1.0 .
docker push your-registry/task-management-frontend:v1.0
```

### 2. Deploy to Kubernetes
```bash
# Create namespace
kubectl create namespace task-management

# Deploy database
kubectl apply -f 7-kubernetes/mysql-deployment.yaml -n task-management
kubectl apply -f 7-kubernetes/mysql-service.yaml -n task-management

# Deploy backend
kubectl apply -f 7-kubernetes/task-api-deployment.yaml -n task-management
kubectl apply -f 7-kubernetes/task-api-service.yaml -n task-management

# Deploy frontend
kubectl apply -f 7-kubernetes/frontend-deployment.yaml -n task-management
kubectl apply -f 7-kubernetes/frontend-service.yaml -n task-management

# Deploy ingress
kubectl apply -f 7-kubernetes/ingress.yaml -n task-management

# Deploy monitoring
kubectl apply -f 9-monitoring/ -n task-management
```

### 3. Verify Deployment
```bash
# Check pods
kubectl get pods -n task-management

# Check services
kubectl get svc -n task-management

# Check ingress
kubectl get ingress -n task-management

# View logs
kubectl logs -f deployment/task-frontend -n task-management
kubectl logs -f deployment/task-backend -n task-management
```

## CI/CD Pipeline

### GitHub Actions
```bash
# Setup secrets in GitHub
DOCKER_USERNAME=your-username
DOCKER_PASSWORD=your-password
KUBECONFIG=base64-encoded-kubeconfig

# Pipeline triggers on:
# - Push to main/develop
# - Pull requests to main
```

### Jenkins
```bash
# Required credentials:
# - docker-hub-credentials
# - kubeconfig

# Pipeline stages:
# 1. Test backend
# 2. Build images (parallel)
# 3. Deploy to Kubernetes
```

## Environment Configuration

### Development
```yaml
# docker-compose.yml
environment:
  SPRING_PROFILES_ACTIVE: dev
  SPRING_DATASOURCE_URL: jdbc:mysql://mysql:3306/taskdb
```

### Production
```yaml
# kubernetes deployment
env:
- name: SPRING_PROFILES_ACTIVE
  value: "prod"
- name: SPRING_DATASOURCE_URL
  value: "jdbc:mysql://mysql-service:3306/taskdb"
- name: SPRING_DATASOURCE_USERNAME
  valueFrom:
    secretKeyRef:
      name: mysql-secret
      key: username
```

## Scaling

### Horizontal Pod Autoscaler
```bash
# Backend scaling
kubectl autoscale deployment task-backend --cpu-percent=70 --min=2 --max=10

# Frontend scaling
kubectl autoscale deployment task-frontend --cpu-percent=50 --min=2 --max=5
```

### Manual Scaling
```bash
# Scale backend
kubectl scale deployment task-backend --replicas=5

# Scale frontend
kubectl scale deployment task-frontend --replicas=3
```

## Monitoring Setup

### Prometheus Targets
- Backend: `app:8080/actuator/prometheus`
- Frontend: `frontend:80/nginx_status`
- MySQL: `mysql-exporter:9104`

### Grafana Dashboards
- Import dashboard ID: 12900 (Spring Boot)
- Custom frontend dashboard included
- MySQL dashboard ID: 7362

## Security

### Network Policies
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: task-management-netpol
spec:
  podSelector:
    matchLabels:
      app: task-backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: task-frontend
    ports:
    - protocol: TCP
      port: 8080
```

### Secrets Management
```bash
# Create database secret
kubectl create secret generic mysql-secret \
  --from-literal=username=taskuser \
  --from-literal=password=taskpass \
  -n task-management
```

## Backup & Recovery

### Database Backup
```bash
# Create backup job
kubectl create job mysql-backup --from=cronjob/mysql-backup

# Manual backup
kubectl exec mysql-pod -- mysqldump -u root -p taskdb > backup.sql
```

### Application Backup
```bash
# Backup configurations
kubectl get configmap -o yaml > configmaps-backup.yaml
kubectl get secret -o yaml > secrets-backup.yaml
```

## Troubleshooting

### Common Issues
1. **Pod CrashLoopBackOff**
   ```bash
   kubectl describe pod <pod-name>
   kubectl logs <pod-name> --previous
   ```

2. **Service Not Accessible**
   ```bash
   kubectl get endpoints
   kubectl port-forward svc/task-frontend-service 8080:80
   ```

3. **Database Connection Issues**
   ```bash
   kubectl exec -it mysql-pod -- mysql -u root -p
   ```

### Health Checks
```bash
# Backend health
curl http://localhost:8080/actuator/health

# Frontend health
curl http://localhost:3001/

# Database health
kubectl exec mysql-pod -- mysqladmin ping
```

## Performance Tuning

### Resource Limits
```yaml
resources:
  requests:
    memory: "512Mi"
    cpu: "250m"
  limits:
    memory: "1Gi"
    cpu: "500m"
```

### JVM Tuning (Backend)
```yaml
env:
- name: JAVA_OPTS
  value: "-Xmx512m -Xms256m -XX:+UseG1GC"
```

## Rollback Strategy
```bash
# Rollback deployment
kubectl rollout undo deployment/task-backend
kubectl rollout undo deployment/task-frontend

# Check rollout status
kubectl rollout status deployment/task-backend
```

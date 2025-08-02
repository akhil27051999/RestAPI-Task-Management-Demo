# 9-Documentation Files

## api-documentation.md
```markdown
# Task Management API Documentation

## Overview
REST API for managing tasks with full CRUD operations, built with Spring Boot and MySQL.

## Base URL
- **Development**: `http://localhost:8080`
- **Production**: `https://api.taskmanagement.com`

## Authentication
Currently no authentication required. Future versions will implement JWT-based authentication.

## API Endpoints

### Tasks

#### Get All Tasks
```http
GET /api/tasks
```

**Response:**
```json
[
  {
    "id": 1,
    "title": "Complete project documentation",
    "description": "Write comprehensive API documentation",
    "status": "PENDING",
    "createdAt": "2024-01-15T10:30:00",
    "updatedAt": "2024-01-15T10:30:00"
  }
]
```

#### Get Task by ID
```http
GET /api/tasks/{id}
```

**Parameters:**
- `id` (path): Task ID (integer)

**Response:**
```json
{
  "id": 1,
  "title": "Complete project documentation",
  "description": "Write comprehensive API documentation",
  "status": "PENDING",
  "createdAt": "2024-01-15T10:30:00",
  "updatedAt": "2024-01-15T10:30:00"
}
```

**Error Response:**
```json
{
  "status": 404,
  "error": "Not Found",
  "message": "Task not found with id: 1"
}
```

#### Create Task
```http
POST /api/tasks
```

**Request Body:**
```json
{
  "title": "New task title",
  "description": "Task description",
  "status": "PENDING"
}
```

**Response:**
```json
{
  "id": 2,
  "title": "New task title",
  "description": "Task description",
  "status": "PENDING",
  "createdAt": "2024-01-15T11:00:00",
  "updatedAt": "2024-01-15T11:00:00"
}
```

#### Update Task
```http
PUT /api/tasks/{id}
```

**Parameters:**
- `id` (path): Task ID (integer)

**Request Body:**
```json
{
  "title": "Updated task title",
  "description": "Updated description",
  "status": "COMPLETED"
}
```

**Response:**
```json
{
  "id": 1,
  "title": "Updated task title",
  "description": "Updated description",
  "status": "COMPLETED",
  "createdAt": "2024-01-15T10:30:00",
  "updatedAt": "2024-01-15T11:30:00"
}
```

#### Delete Task
```http
DELETE /api/tasks/{id}
```

**Parameters:**
- `id` (path): Task ID (integer)

**Response:** `204 No Content`

### Health & Monitoring

#### Health Check
```http
GET /actuator/health
```

**Response:**
```json
{
  "status": "UP",
  "components": {
    "db": {
      "status": "UP",
      "details": {
        "database": "MySQL",
        "validationQuery": "isValid()"
      }
    }
  }
}
```

#### Metrics
```http
GET /actuator/metrics
```

#### Prometheus Metrics
```http
GET /actuator/prometheus
```

## Data Models

### Task
```json
{
  "id": "integer (auto-generated)",
  "title": "string (required, max 255 chars)",
  "description": "string (optional, max 1000 chars)",
  "status": "enum (PENDING, IN_PROGRESS, COMPLETED, CANCELLED)",
  "createdAt": "datetime (auto-generated)",
  "updatedAt": "datetime (auto-updated)"
}
```

### Task Status Values
- `PENDING`: Task is created but not started
- `IN_PROGRESS`: Task is currently being worked on
- `COMPLETED`: Task is finished
- `CANCELLED`: Task is cancelled

## HTTP Status Codes
- `200 OK`: Successful GET/PUT request
- `201 Created`: Successful POST request
- `204 No Content`: Successful DELETE request
- `400 Bad Request`: Invalid request data
- `404 Not Found`: Resource not found
- `500 Internal Server Error`: Server error

## Error Response Format
```json
{
  "timestamp": "2024-01-15T12:00:00",
  "status": 400,
  "error": "Bad Request",
  "message": "Validation failed",
  "path": "/api/tasks"
}
```

## Rate Limiting
- **Development**: No limits
- **Production**: 100 requests per minute per IP

## Examples

### cURL Examples

**Create a task:**
```bash
curl -X POST http://localhost:8080/api/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Learn Kubernetes",
    "description": "Complete Kubernetes tutorial",
    "status": "PENDING"
  }'
```

**Get all tasks:**
```bash
curl http://localhost:8080/api/tasks
```

**Update a task:**
```bash
curl -X PUT http://localhost:8080/api/tasks/1 \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Learn Kubernetes",
    "description": "Complete Kubernetes tutorial",
    "status": "COMPLETED"
  }'
```

**Delete a task:**
```bash
curl -X DELETE http://localhost:8080/api/tasks/1
```

### JavaScript Examples

**Using Fetch API:**
```javascript
// Create task
const createTask = async () => {
  const response = await fetch('/api/tasks', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      title: 'New Task',
      description: 'Task description',
      status: 'PENDING'
    })
  });
  return response.json();
};

// Get all tasks
const getTasks = async () => {
  const response = await fetch('/api/tasks');
  return response.json();
};
```

## SDKs and Libraries
Currently no official SDKs available. Standard HTTP clients can be used with any programming language.

## Changelog
- **v1.0.0**: Initial release with basic CRUD operations
- **v1.1.0**: Added health checks and metrics endpoints
- **v1.2.0**: Enhanced error handling and validation
```

## deployment-guide.md
```markdown
# Deployment Guide

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

## troubleshooting.md
```markdown
# Troubleshooting Guide

## Common Issues and Solutions

### Application Issues

#### Application Won't Start

**Symptoms:**
- Pod in CrashLoopBackOff state
- Application logs show startup errors
- Health check endpoints not responding

**Diagnosis:**
```bash
# Check pod status
kubectl get pods -n task-management

# Check pod logs
kubectl logs -f deployment/task-api -n task-management

# Describe pod for events
kubectl describe pod <pod-name> -n task-management
```

**Common Causes & Solutions:**

1. **Database Connection Issues**
```bash
# Check database connectivity
kubectl exec -it deployment/task-api -n task-management -- nc -zv mysql-service 3306

# Verify database credentials
kubectl get secret task-api-secret -n task-management -o yaml
echo "dGFza3VzZXI=" | base64 -d  # Decode secret values
```

2. **Missing Environment Variables**
```bash
# Check environment variables
kubectl exec -it deployment/task-api -n task-management -- env | grep SPRING

# Update deployment with missing variables
kubectl patch deployment task-api -n task-management -p '{"spec":{"template":{"spec":{"containers":[{"name":"task-api","env":[{"name":"SPRING_PROFILES_ACTIVE","value":"prod"}]}]}}}}'
```

3. **Resource Constraints**
```bash
# Check resource usage
kubectl top pods -n task-management

# Increase resource limits
kubectl patch deployment task-api -n task-management -p '{"spec":{"template":{"spec":{"containers":[{"name":"task-api","resources":{"limits":{"memory":"2Gi","cpu":"1000m"}}}]}}}}'
```

#### High Memory Usage

**Symptoms:**
- Pods being OOMKilled
- High memory usage in monitoring
- Application becoming unresponsive

**Diagnosis:**
```bash
# Check memory usage
kubectl top pods -n task-management

# Check JVM memory
kubectl exec -it deployment/task-api -n task-management -- jstat -gc <pid>

# Check heap dump (if available)
kubectl exec -it deployment/task-api -n task-management -- jcmd <pid> GC.run_finalization
```

**Solutions:**
```bash
# Increase memory limits
kubectl patch deployment task-api -n task-management -p '{"spec":{"template":{"spec":{"containers":[{"name":"task-api","resources":{"limits":{"memory":"2Gi"}}}]}}}}'

# Optimize JVM settings
kubectl patch deployment task-api -n task-management -p '{"spec":{"template":{"spec":{"containers":[{"name":"task-api","env":[{"name":"JAVA_OPTS","value":"-XX:MaxRAMPercentage=70.0 -XX:+UseG1GC"}]}]}}}}'
```

#### Slow Response Times

**Symptoms:**
- API responses taking >2 seconds
- Timeout errors
- High CPU usage

**Diagnosis:**
```bash
# Check response times in Grafana
# URL: http://grafana.taskmanagement.local

# Check database performance
kubectl exec -it deployment/mysql -n task-management -- mysql -u root -p -e "SHOW PROCESSLIST;"

# Check application metrics
curl http://localhost:8080/actuator/metrics/http.server.requests
```

**Solutions:**
```bash
# Scale application horizontally
kubectl scale deployment task-api --replicas=5 -n task-management

# Add database indexes
kubectl exec -it deployment/mysql -n task-management -- mysql -u root -p taskdb -e "CREATE INDEX idx_status ON tasks(status);"

# Enable connection pooling
# Update application.yml with HikariCP settings
```

### Database Issues

#### Database Connection Refused

**Symptoms:**
- "Connection refused" errors in application logs
- Database health check failing
- Unable to connect to MySQL

**Diagnosis:**
```bash
# Check MySQL pod status
kubectl get pods -l app=mysql -n task-management

# Check MySQL logs
kubectl logs -f deployment/mysql -n task-management

# Test connection from application pod
kubectl exec -it deployment/task-api -n task-management -- nc -zv mysql-service 3306
```

**Solutions:**
```bash
# Restart MySQL pod
kubectl rollout restart deployment/mysql -n task-management

# Check service configuration
kubectl get svc mysql-service -n task-management -o yaml

# Verify network policies
kubectl get networkpolicy -n task-management
```

#### Database Performance Issues

**Symptoms:**
- Slow query execution
- High database CPU usage
- Connection pool exhaustion

**Diagnosis:**
```bash
# Check slow query log
kubectl exec -it deployment/mysql -n task-management -- mysql -u root -p -e "SHOW VARIABLES LIKE 'slow_query_log';"

# Check running processes
kubectl exec -it deployment/mysql -n task-management -- mysql -u root -p -e "SHOW PROCESSLIST;"

# Check database size
kubectl exec -it deployment/mysql -n task-management -- mysql -u root -p -e "SELECT table_schema, ROUND(SUM(data_length + index_length) / 1024 / 1024, 1) AS 'DB Size in MB' FROM information_schema.tables GROUP BY table_schema;"
```

**Solutions:**
```bash
# Add database indexes
kubectl exec -it deployment/mysql -n task-management -- mysql -u root -p taskdb -e "
CREATE INDEX idx_created_at ON tasks(created_at);
CREATE INDEX idx_status_created ON tasks(status, created_at);
"

# Optimize MySQL configuration
kubectl patch deployment mysql -n task-management -p '{"spec":{"template":{"spec":{"containers":[{"name":"mysql","env":[{"name":"MYSQL_INNODB_BUFFER_POOL_SIZE","value":"1G"}]}]}}}}'

# Scale database resources
kubectl patch deployment mysql -n task-management -p '{"spec":{"template":{"spec":{"containers":[{"name":"mysql","resources":{"limits":{"memory":"4Gi","cpu":"2000m"}}}]}}}}'
```

### Networking Issues

#### Service Not Accessible

**Symptoms:**
- 503 Service Unavailable errors
- Connection timeouts
- DNS resolution failures

**Diagnosis:**
```bash
# Check service endpoints
kubectl get endpoints -n task-management

# Test service connectivity
kubectl run test-pod --image=busybox -it --rm -- nslookup task-api-service.task-management.svc.cluster.local

# Check ingress status
kubectl describe ingress task-api-ingress -n task-management
```

**Solutions:**
```bash
# Restart ingress controller
kubectl rollout restart deployment/nginx-ingress-controller -n ingress-nginx

# Update service selector
kubectl patch service task-api-service -n task-management -p '{"spec":{"selector":{"app":"task-api"}}}'

# Check network policies
kubectl get networkpolicy -n task-management
```

#### Ingress Not Working

**Symptoms:**
- 404 Not Found from ingress
- SSL certificate issues
- Ingress controller errors

**Diagnosis:**
```bash
# Check ingress controller logs
kubectl logs -f deployment/nginx-ingress-controller -n ingress-nginx

# Check certificate status
kubectl describe certificate task-api-tls -n task-management

# Test ingress rules
kubectl get ingress task-api-ingress -n task-management -o yaml
```

**Solutions:**
```bash
# Update ingress annotations
kubectl annotate ingress task-api-ingress -n task-management nginx.ingress.kubernetes.io/rewrite-target=/

# Recreate certificate
kubectl delete certificate task-api-tls -n task-management
kubectl apply -f k8s/ingress.yaml

# Check DNS configuration
nslookup api.taskmanagement.local
```

### Kubernetes Issues

#### Pods Stuck in Pending

**Symptoms:**
- Pods remain in Pending state
- Insufficient resources warnings
- Scheduling failures

**Diagnosis:**
```bash
# Check pod events
kubectl describe pod <pod-name> -n task-management

# Check node resources
kubectl top nodes

# Check resource quotas
kubectl describe resourcequota -n task-management
```

**Solutions:**
```bash
# Scale cluster nodes (if using managed service)
# AWS EKS example:
aws eks update-nodegroup --cluster-name task-management-cluster --nodegroup-name main-nodes --scaling-config minSize=2,maxSize=10,desiredSize=4

# Reduce resource requests
kubectl patch deployment task-api -n task-management -p '{"spec":{"template":{"spec":{"containers":[{"name":"task-api","resources":{"requests":{"memory":"256Mi","cpu":"100m"}}}]}}}}'

# Check and remove resource quotas if needed
kubectl delete resourcequota <quota-name> -n task-management
```

#### PVC Stuck in Pending

**Symptoms:**
- PersistentVolumeClaim in Pending state
- No available storage
- StorageClass issues

**Diagnosis:**
```bash
# Check PVC status
kubectl describe pvc mysql-pvc -n task-management

# Check available storage classes
kubectl get storageclass

# Check persistent volumes
kubectl get pv
```

**Solutions:**
```bash
# Create storage class if missing
kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp2
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp2
  fsType: ext4
EOF

# Update PVC storage class
kubectl patch pvc mysql-pvc -n task-management -p '{"spec":{"storageClassName":"gp2"}}'
```

### Monitoring Issues

#### Prometheus Not Scraping Metrics

**Symptoms:**
- Missing metrics in Prometheus
- Targets showing as down
- No data in Grafana dashboards

**Diagnosis:**
```bash
# Check Prometheus targets
curl http://prometheus.taskmanagement.local/targets

# Check service monitor
kubectl get servicemonitor -n monitoring

# Test metrics endpoint
kubectl exec -it deployment/task-api -n task-management -- curl localhost:8080/actuator/prometheus
```

**Solutions:**
```bash
# Update service monitor labels
kubectl patch servicemonitor task-api -n monitoring -p '{"spec":{"selector":{"matchLabels":{"app":"task-api"}}}}'

# Restart Prometheus
kubectl rollout restart deployment/prometheus -n monitoring

# Check network policies
kubectl get networkpolicy -n monitoring
```

#### Grafana Dashboards Not Loading

**Symptoms:**
- Empty dashboards
- "No data" messages
- Dashboard import failures

**Diagnosis:**
```bash
# Check Grafana logs
kubectl logs -f deployment/grafana -n monitoring

# Check datasource configuration
kubectl exec -it deployment/grafana -n monitoring -- curl localhost:3000/api/datasources

# Test Prometheus connectivity
kubectl exec -it deployment/grafana -n monitoring -- curl prometheus-service:9090/api/v1/query?query=up
```

**Solutions:**
```bash
# Update datasource URL
kubectl patch configmap grafana-datasources -n monitoring -p '{"data":{"datasources.yaml":"apiVersion: 1\ndatasources:\n- name: Prometheus\n  type: prometheus\n  url: http://prometheus-service:9090\n  access: proxy\n  isDefault: true"}}'

# Restart Grafana
kubectl rollout restart deployment/grafana -n monitoring

# Reimport dashboards
kubectl delete configmap grafana-dashboards -n monitoring
kubectl apply -f monitoring/grafana/dashboards/
```

## Performance Troubleshooting

### High CPU Usage

**Diagnosis:**
```bash
# Check CPU usage
kubectl top pods -n task-management

# Check JVM thread dump
kubectl exec -it deployment/task-api -n task-management -- jstack <pid>

# Check application metrics
curl http://localhost:8080/actuator/metrics/system.cpu.usage
```

**Solutions:**
```bash
# Scale horizontally
kubectl scale deployment task-api --replicas=5 -n task-management

# Optimize JVM garbage collection
kubectl patch deployment task-api -n task-management -p '{"spec":{"template":{"spec":{"containers":[{"name":"task-api","env":[{"name":"JAVA_OPTS","value":"-XX:+UseG1GC -XX:MaxGCPauseMillis=200"}]}]}}}}'

# Add CPU limits
kubectl patch deployment task-api -n task-management -p '{"spec":{"template":{"spec":{"containers":[{"name":"task-api","resources":{"limits":{"cpu":"1000m"}}}]}}}}'
```

### Memory Leaks

**Diagnosis:**
```bash
# Monitor memory usage over time
kubectl top pods -n task-management --sort-by=memory

# Generate heap dump
kubectl exec -it deployment/task-api -n task-management -- jcmd <pid> GC.run_finalization

# Check for memory leaks in application code
# Review connection pools, caches, and static collections
```

**Solutions:**
```bash
# Restart pods periodically (temporary fix)
kubectl rollout restart deployment/task-api -n task-management

# Implement proper resource cleanup in application code
# Add connection pool monitoring
# Review caching strategies
```

## Debugging Commands

### Application Debugging
```bash
# Get application logs
kubectl logs -f deployment/task-api -n task-management

# Execute commands in pod
kubectl exec -it deployment/task-api -n task-management -- bash

# Port forward for local debugging
kubectl port-forward deployment/task-api 8080:8080 -n task-management

# Check application configuration
kubectl exec -it deployment/task-api -n task-management -- env | grep SPRING
```

### Database Debugging
```bash
# Connect to database
kubectl exec -it deployment/mysql -n task-management -- mysql -u root -p taskdb

# Check database status
kubectl exec -it deployment/mysql -n task-management -- mysqladmin status -u root -p

# Monitor database queries
kubectl exec -it deployment/mysql -n task-management -- mysql -u root -p -e "SHOW PROCESSLIST;"
```

### Network Debugging
```bash
# Test connectivity between pods
kubectl exec -it deployment/task-api -n task-management -- nc -zv mysql-service 3306

# Check DNS resolution
kubectl exec -it deployment/task-api -n task-management -- nslookup mysql-service

# Test external connectivity
kubectl exec -it deployment/task-api -n task-management -- curl -I https://google.com
```

## Emergency Procedures

### Application Down
```bash
# Quick restart
kubectl rollout restart deployment/task-api -n task-management

# Scale to zero and back (if restart doesn't work)
kubectl scale deployment task-api --replicas=0 -n task-management
kubectl scale deployment task-api --replicas=3 -n task-management

# Rollback to previous version
kubectl rollout undo deployment/task-api -n task-management
```

### Database Corruption
```bash
# Stop application
kubectl scale deployment task-api --replicas=0 -n task-management

# Backup current database
kubectl exec -it deployment/mysql -n task-management -- mysqldump -u root -p taskdb > emergency-backup.sql

# Restore from backup
kubectl exec -i deployment/mysql -n task-management -- mysql -u root -p taskdb < last-good-backup.sql

# Restart application
kubectl scale deployment task-api --replicas=3 -n task-management
```

### Complete System Recovery
```bash
# Delete and recreate namespace
kubectl delete namespace task-management
kubectl apply -f k8s/

# Restore from backup
kubectl exec -i deployment/mysql -n task-management -- mysql -u root -p taskdb < backup.sql

# Verify system health
kubectl get all -n task-management
curl http://api.taskmanagement.local/actuator/health
```

This troubleshooting guide covers the most common issues and their solutions for the Task Management API deployment.
```

## best-practices.md
```markdown
# Best Practices Guide

## Development Best Practices

### Code Quality

#### Code Structure
- Follow layered architecture (Controller → Service → Repository)
- Use dependency injection with Spring annotations
- Implement proper error handling with custom exceptions
- Write comprehensive unit and integration tests
- Maintain test coverage above 80%

#### API Design
```java
// Good: RESTful endpoint design
@GetMapping("/api/tasks/{id}")
public ResponseEntity<TaskDTO> getTask(@PathVariable Long id) {
    return ResponseEntity.ok(taskService.getTaskById(id));
}

// Good: Proper HTTP status codes
@PostMapping("/api/tasks")
public ResponseEntity<TaskDTO> createTask(@Valid @RequestBody CreateTaskRequest request) {
    TaskDTO created = taskService.createTask(request);
    return ResponseEntity.status(HttpStatus.CREATED).body(created);
}
```

#### Error Handling
```java
// Good: Global exception handler
@RestControllerAdvice
public class GlobalExceptionHandler {
    
    @ExceptionHandler(TaskNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleTaskNotFound(TaskNotFoundException ex) {
        ErrorResponse error = ErrorResponse.builder()
                .timestamp(LocalDateTime.now())
                .status(HttpStatus.NOT_FOUND.value())
                .error("Not Found")
                .message(ex.getMessage())
                .build();
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
    }
}
```

#### Validation
```java
// Good: Input validation
public class CreateTaskRequest {
    @NotBlank(message = "Title is required")
    @Size(max = 255, message = "Title must not exceed 255 characters")
    private String title;
    
    @Size(max = 1000, message = "Description must not exceed 1000 characters")
    private String description;
}
```

### Database Best Practices

#### Entity Design
```java
// Good: Proper entity annotations
@Entity
@Table(name = "tasks", indexes = {
    @Index(name = "idx_status", columnList = "status"),
    @Index(name = "idx_created_at", columnList = "created_at")
})
public class Task {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
    
    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
```

#### Repository Patterns
```java
// Good: Custom query methods
@Repository
public interface TaskRepository extends JpaRepository<Task, Long> {
    
    @Query("SELECT t FROM Task t WHERE t.status = :status AND t.createdAt >= :since")
    List<Task> findRecentTasksByStatus(@Param("status") TaskStatus status, 
                                      @Param("since") LocalDateTime since);
    
    @Modifying
    @Query("UPDATE Task t SET t.status = :newStatus WHERE t.status = :oldStatus")
    int bulkUpdateStatus(@Param("oldStatus") TaskStatus oldStatus, 
                        @Param("newStatus") TaskStatus newStatus);
}
```

#### Connection Pool Configuration
```yaml
# Good: HikariCP configuration
spring:
  datasource:
    hikari:
      maximum-pool-size: 20
      minimum-idle: 5
      connection-timeout: 30000
      idle-timeout: 600000
      max-lifetime: 1800000
      leak-detection-threshold: 60000
```

### Security Best Practices

#### Input Validation
```java
// Good: Comprehensive validation
@PostMapping("/api/tasks")
public ResponseEntity<TaskDTO> createTask(@Valid @RequestBody CreateTaskRequest request) {
    // Validation is handled by @Valid annotation
    TaskDTO created = taskService.createTask(request);
    return ResponseEntity.status(HttpStatus.CREATED).body(created);
}
```

#### SQL Injection Prevention
```java
// Good: Use parameterized queries
@Query("SELECT t FROM Task t WHERE t.title LIKE %:keyword%")
List<Task> searchByTitle(@Param("keyword") String keyword);

// Bad: String concatenation (vulnerable to SQL injection)
// "SELECT * FROM tasks WHERE title LIKE '%" + keyword + "%'"
```

#### Secrets Management
```yaml
# Good: Use environment variables
spring:
  datasource:
    username: ${DB_USERNAME}
    password: ${DB_PASSWORD}

# Bad: Hardcoded credentials
# username: admin
# password: password123
```

## Containerization Best Practices

### Dockerfile Optimization

#### Multi-stage Build
```dockerfile
# Good: Multi-stage build
FROM openjdk:17-jdk-slim as builder
WORKDIR /app
COPY . .
RUN ./mvnw clean package -DskipTests

FROM openjdk:17-jre-slim
COPY --from=builder /app/target/app.jar app.jar
ENTRYPOINT ["java", "-jar", "app.jar"]
```

#### Security Hardening
```dockerfile
# Good: Non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser
USER appuser

# Good: Health checks
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1
```

#### Resource Optimization
```dockerfile
# Good: JVM optimization for containers
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -XX:+UseG1GC"
```

### Docker Compose Best Practices

#### Service Dependencies
```yaml
# Good: Health check dependencies
services:
  app:
    depends_on:
      mysql:
        condition: service_healthy
  
  mysql:
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 30s
      timeout: 10s
      retries: 3
```

#### Resource Limits
```yaml
# Good: Resource constraints
services:
  app:
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '0.5'
        reservations:
          memory: 512M
          cpus: '0.25'
```

## Kubernetes Best Practices

### Resource Management

#### Resource Requests and Limits
```yaml
# Good: Proper resource configuration
resources:
  requests:
    memory: "512Mi"
    cpu: "250m"
  limits:
    memory: "1Gi"
    cpu: "500m"
```

#### Horizontal Pod Autoscaler
```yaml
# Good: HPA configuration
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: task-api-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: task-api
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

### Security Best Practices

#### Pod Security Context
```yaml
# Good: Security context
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000
  capabilities:
    drop:
    - ALL
  readOnlyRootFilesystem: true
```

#### Network Policies
```yaml
# Good: Network policy
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: task-api-netpol
spec:
  podSelector:
    matchLabels:
      app: task-api
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: nginx-ingress
    ports:
    - protocol: TCP
      port: 8080
```

#### Secret Management
```yaml
# Good: Use secrets for sensitive data
env:
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: task-api-secret
      key: mysql-password
```

### High Availability

#### Pod Disruption Budget
```yaml
# Good: PDB configuration
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: task-api-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: task-api
```

#### Anti-Affinity Rules
```yaml
# Good: Pod anti-affinity
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        labelSelector:
          matchExpressions:
          - key: app
            operator: In
            values:
            - task-api
        topologyKey: kubernetes.io/hostname
```

### Health Checks

#### Comprehensive Probes
```yaml
# Good: All three probe types
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

startupProbe:
  httpGet:
    path: /actuator/health
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10
  failureThreshold: 12
```

## CI/CD Best Practices

### Pipeline Design

#### Stage Separation
```yaml
# Good: Clear stage separation
jobs:
  test:
    name: Test
    runs-on: ubuntu-latest
    steps:
      - name: Run Tests
        run: mvn test

  security:
    name: Security Scan
    needs: test
    steps:
      - name: OWASP Scan
        run: mvn dependency-check:check

  build:
    name: Build & Push
    needs: [test, security]
    steps:
      - name: Build Image
        run: docker build -t app:${{ github.sha }} .
```

#### Environment Promotion
```yaml
# Good: Environment-specific deployments
deploy-dev:
  if: github.ref == 'refs/heads/develop'
  environment: development

deploy-prod:
  if: github.ref == 'refs/heads/main'
  environment: production
  needs: [deploy-staging]
```

### GitOps Best Practices

#### Repository Structure
```
gitops-repo/
├── environments/
│   ├── dev/
│   │   ├── kustomization.yaml
│   │   └── values.yaml
│   ├── staging/
│   └── prod/
└── base/
    ├── deployment.yaml
    ├── service.yaml
    └── kustomization.yaml
```

#### ArgoCD Configuration
```yaml
# Good: ArgoCD application
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: task-management-api
spec:
  project: default
  source:
    repoURL: https://github.com/org/gitops-repo.git
    targetRevision: HEAD
    path: environments/prod
  destination:
    server: https://kubernetes.default.svc
    namespace: task-management
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

## Monitoring Best Practices

### Metrics Collection

#### Application Metrics
```java
// Good: Custom metrics
@Component
public class TaskMetrics {
    private final Counter taskCreatedCounter;
    private final Timer taskProcessingTimer;
    
    public TaskMetrics(MeterRegistry meterRegistry) {
        this.taskCreatedCounter = Counter.builder("tasks.created.total")
            .description("Total number of tasks created")
            .register(meterRegistry);
            
        this.taskProcessingTimer = Timer.builder("task.processing.duration")
            .description("Time taken to process tasks")
            .register(meterRegistry);
    }
}
```

#### Prometheus Configuration
```yaml
# Good: Comprehensive scrape config
scrape_configs:
  - job_name: 'task-management-api'
    kubernetes_sd_configs:
      - role: endpoints
    relabel_configs:
      - source_labels: [__meta_kubernetes_service_name]
        action: keep
        regex: task-management-service
    metrics_path: '/actuator/prometheus'
    scrape_interval: 30s
```

### Alerting Rules

#### Meaningful Alerts
```yaml
# Good: Actionable alerts
groups:
  - name: task-management-alerts
    rules:
      - alert: HighErrorRate
        expr: rate(http_server_requests_seconds_count{status=~"5.."}[5m]) / rate(http_server_requests_seconds_count[5m]) > 0.05
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High error rate detected"
          description: "Error rate is {{ $value | humanizePercentage }} for {{ $labels.instance }}"
          runbook_url: "https://wiki.company.com/runbooks/high-error-rate"
```

### Logging Best Practices

#### Structured Logging
```java
// Good: Structured logging
@Slf4j
public class TaskService {
    public TaskDTO createTask(CreateTaskRequest request) {
        log.info("Creating task with title: {}", request.getTitle());
        
        try {
            Task task = taskMapper.toEntity(request);
            Task saved = taskRepository.save(task);
            
            log.info("Task created successfully with id: {}", saved.getId());
            return taskMapper.toDTO(saved);
        } catch (Exception e) {
            log.error("Failed to create task with title: {}", request.getTitle(), e);
            throw new TaskCreationException("Failed to create task", e);
        }
    }
}
```

#### Log Levels
```yaml
# Good: Environment-specific log levels
logging:
  level:
    com.taskapi: INFO
    org.springframework.web: WARN
    org.hibernate.SQL: WARN
  pattern:
    console: "%d{yyyy-MM-dd HH:mm:ss} [%thread] %-5level %logger{36} - %msg%n"
```

## Performance Best Practices

### Database Optimization

#### Indexing Strategy
```sql
-- Good: Strategic indexes
CREATE INDEX idx_status_created ON tasks(status, created_at);
CREATE INDEX idx_assigned_user ON tasks(assigned_to) WHERE assigned_to IS NOT NULL;
CREATE INDEX idx_due_date ON tasks(due_date) WHERE due_date IS NOT NULL;
```

#### Query Optimization
```java
// Good: Efficient queries
@Query("SELECT t FROM Task t WHERE t.status = :status AND t.createdAt >= :since ORDER BY t.createdAt DESC")
Page<Task> findRecentTasksByStatus(@Param("status") TaskStatus status, 
                                  @Param("since") LocalDateTime since, 
                                  Pageable pageable);
```

### Caching Strategy

#### Application-Level Caching
```java
// Good: Strategic caching
@Service
public class TaskService {
    
    @Cacheable(value = "tasks", key = "#id")
    public TaskDTO getTaskById(Long id) {
        return taskRepository.findById(id)
                .map(taskMapper::toDTO)
                .orElseThrow(() -> new TaskNotFoundException("Task not found"));
    }
    
    @CacheEvict(value = "tasks", key = "#id")
    public void deleteTask(Long id) {
        taskRepository.deleteById(id);
    }
}
```

### JVM Tuning

#### Container-Optimized Settings
```yaml
# Good: JVM optimization
env:
- name: JAVA_OPTS
  value: >-
    -XX:+UseContainerSupport
    -XX:MaxRAMPercentage=75.0
    -XX:+UseG1GC
    -XX:MaxGCPauseMillis=200
    -XX:+UnlockExperimentalVMOptions
    -XX:+UseCGroupMemoryLimitForHeap
```

## Disaster Recovery Best Practices

### Backup Strategy

#### Database Backups
```bash
# Good: Automated backup script
#!/bin/bash
BACKUP_DIR="/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="taskdb_backup_${DATE}.sql"

kubectl exec -it deployment/mysql -n task-management -- \
  mysqldump -u root -p${MYSQL_ROOT_PASSWORD} taskdb > ${BACKUP_DIR}/${BACKUP_FILE}

# Compress backup
gzip ${BACKUP_DIR}/${BACKUP_FILE}

# Upload to S3
aws s3 cp ${BACKUP_DIR}/${BACKUP_FILE}.gz s3://backups-bucket/database/
```

#### Configuration Backups
```bash
# Good: Kubernetes resource backup
kubectl get all,configmap,secret,pvc -n task-management -o yaml > k8s-backup-$(date +%Y%m%d).yaml
```

### Recovery Procedures

#### Database Recovery
```bash
# Good: Recovery script
#!/bin/bash
BACKUP_FILE=$1

# Stop application
kubectl scale deployment task-api --replicas=0 -n task-management

# Restore database
kubectl exec -i deployment/mysql -n task-management -- \
  mysql -u root -p${MYSQL_ROOT_PASSWORD} taskdb < ${BACKUP_FILE}

# Start application
kubectl scale deployment task-api --replicas=3 -n task-management

# Verify recovery
kubectl wait --for=condition=ready pod -l app=task-api -n task-management --timeout=300s
```

This best practices guide provides comprehensive guidelines for developing, deploying, and maintaining the Task Management API in production environments.
```

## Quick Reference

### Deploy Documentation
```bash
# Create documentation namespace
kubectl create namespace documentation

# Deploy as ConfigMaps for easy access
kubectl create configmap api-docs --from-file=api-documentation.md -n documentation
kubectl create configmap deployment-guide --from-file=deployment-guide.md -n documentation
kubectl create configmap troubleshooting --from-file=troubleshooting.md -n documentation
kubectl create configmap best-practices --from-file=best-practices.md -n documentation
```

### Access Documentation
```bash
# View documentation
kubectl get configmap api-docs -n documentation -o yaml
kubectl get configmap deployment-guide -n documentation -o yaml
kubectl get configmap troubleshooting -n documentation -o yaml
kubectl get configmap best-practices -n documentation -o yaml
```

This documentation provides comprehensive guides for API usage, deployment procedures, troubleshooting common issues, and following best practices for production environments.

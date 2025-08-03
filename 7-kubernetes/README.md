# Kubernetes Deployment for Task Management API

## Overview
This directory contains Kubernetes manifests for deploying the Task Management API with MySQL database in a production-ready configuration.

## Architecture
- **Namespace**: Isolated environment for the application
- **MySQL Database**: Persistent database with PVC storage
- **Task API**: Spring Boot application with 3 replicas
- **Ingress**: NGINX ingress with SSL termination
- **HPA**: Auto-scaling based on CPU/memory usage
- **PDB**: Pod disruption budgets for high availability

## Prerequisites
- Kubernetes cluster (v1.20+)
- NGINX Ingress Controller
- cert-manager for SSL certificates
- StorageClass `gp2` available

## Quick Deployment

### 1. Deploy All Resources
```bash
# Apply all manifests
kubectl apply -f .

# Check deployment status
kubectl get all -n task-management
```

### 2. Verify Deployment
```bash
# Check pods
kubectl get pods -n task-management

# Check services
kubectl get svc -n task-management

# Check ingress
kubectl get ingress -n task-management
```

### 3. Access Application
```bash
# Port forward for local access
kubectl port-forward svc/task-api-service 8080:80 -n task-management

# Test API
curl http://localhost:8080/api/tasks
curl http://localhost:8080/actuator/health
```

## Step-by-Step Deployment

### 1. Create Namespace and Secrets
```bash
kubectl apply -f namespace.yaml
kubectl apply -f secret.yaml
kubectl apply -f configmap.yaml
```

### 2. Deploy MySQL Database
```bash
kubectl apply -f mysql-deployment.yaml
kubectl apply -f mysql-service.yaml

# Wait for MySQL to be ready
kubectl wait --for=condition=ready pod -l app=mysql -n task-management --timeout=300s
```

### 3. Deploy Task API
```bash
kubectl apply -f task-api-deployment.yaml
kubectl apply -f task-api-service.yaml

# Wait for API to be ready
kubectl wait --for=condition=ready pod -l app=task-api -n task-management --timeout=300s
```

### 4. Configure Ingress and Scaling
```bash
kubectl apply -f ingress.yaml
kubectl apply -f hpa.yaml
kubectl apply -f pdb.yaml
```

## Configuration

### Environment Variables
Update secrets in `secret.yaml`:
- `mysql-username`: Database username
- `mysql-password`: Database password
- `mysql-root-password`: MySQL root password
- `mysql-database`: Database name

### Image Configuration
Update image in `task-api-deployment.yaml`:
```yaml
image: your-registry/task-management-api:v1.0.0
```

### Domain Configuration
Update domain in `ingress.yaml`:
```yaml
- host: your-domain.com
```

## Monitoring

### Health Checks
```bash
# Application health
kubectl exec -it deployment/task-api -n task-management -- curl localhost:8080/actuator/health

# Database health
kubectl exec -it deployment/mysql -n task-management -- mysqladmin ping
```

### Logs
```bash
# Application logs
kubectl logs -f deployment/task-api -n task-management

# Database logs
kubectl logs -f deployment/mysql -n task-management
```

### Metrics
```bash
# HPA status
kubectl get hpa -n task-management

# Pod metrics
kubectl top pods -n task-management
```

## Scaling

### Manual Scaling
```bash
# Scale application
kubectl scale deployment task-api --replicas=5 -n task-management

# Check scaling
kubectl get pods -n task-management
```

### Auto-scaling
HPA automatically scales based on:
- CPU utilization > 70%
- Memory utilization > 80%
- Min replicas: 2
- Max replicas: 10

## Troubleshooting

### Common Issues

1. **Pods not starting**
```bash
kubectl describe pod <pod-name> -n task-management
kubectl logs <pod-name> -n task-management
```

2. **Database connection issues**
```bash
# Check MySQL service
kubectl get svc mysql-service -n task-management

# Test connection
kubectl exec -it deployment/task-api -n task-management -- nc -zv mysql-service 3306
```

3. **Ingress not working**
```bash
kubectl describe ingress task-api-ingress -n task-management
kubectl get events -n task-management
```

### Cleanup
```bash
# Delete all resources
kubectl delete -f .

# Or delete namespace
kubectl delete namespace task-management
```

## Security Considerations
- Secrets are base64 encoded (use external secret management in production)
- Non-root containers with security contexts
- Network policies for traffic isolation
- Resource limits to prevent resource exhaustion
- Pod disruption budgets for availability

## Production Checklist
- [ ] Update default passwords in secrets
- [ ] Configure proper domain and SSL certificates
- [ ] Set up monitoring and alerting
- [ ] Configure backup strategy for database
- [ ] Implement network policies
- [ ] Set up log aggregation
- [ ] Configure resource quotas
- [ ] Test disaster recovery procedures


## Deployment Commands

### Quick Start
```bash
# Deploy everything
kubectl apply -f 6-kubernetes/

# Check status
kubectl get all -n task-management

# Access application
kubectl port-forward svc/task-api-service 8080:80 -n task-management
curl http://localhost:8080/api/tasks
```

### Individual Components
```bash
# Deploy in order
kubectl apply -f 6-kubernetes/namespace.yaml
kubectl apply -f 6-kubernetes/secret.yaml
kubectl apply -f 6-kubernetes/configmap.yaml
kubectl apply -f 6-kubernetes/mysql-deployment.yaml
kubectl apply -f 6-kubernetes/mysql-service.yaml
kubectl apply -f 6-kubernetes/task-api-deployment.yaml
kubectl apply -f 6-kubernetes/task-api-service.yaml
kubectl apply -f 6-kubernetes/ingress.yaml
kubectl apply -f 6-kubernetes/hpa.yaml
kubectl apply -f 6-kubernetes/pdb.yaml
```


## ✅ Why do we have fewer manifest files for the frontend?
**You typically only see:**
- deployment.yaml
- service.yaml
- ingress.yaml

**Because that's often all that’s needed for frontend apps like React/Vue/Angular, which are static web apps. These don’t need as much infrastructure as a backend service.**
## 🔍 Now, compare it to the backend + database setup:

| File                             | Backend Use                                                   | Frontend Use                                                                              |
| -------------------------------- | ------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| `configmap.yaml`                 | Used to pass environment configs (DB URL, log level, etc.)    | Rarely needed; frontend config is usually bundled at build time or served via static JSON |
| `hpa.yaml`                       | Backend needs autoscaling due to load                         | Frontend is static and served through NGINX or similar — not CPU-intensive                |
| `ingress.yaml`                   | Needed to expose backend endpoints via HTTP(S)                | Also needed to expose the frontend (React app)                                            |
| `mysql-deployment.yaml`          | Deploys MySQL DB                                              | ❌ Not applicable to frontend                                                             |
| `mysql-service.yaml`             | Internal service for backend to reach MySQL                   | ❌ Not needed for frontend                                                                |
| `namespace.yaml`                 | Logical grouping of backend components                        | Could be reused, but often frontend is in same namespace                                  |
| `pdb.yaml` (PodDisruptionBudget) | Helps ensure backend API remains available during disruptions | ❌ Not critical for frontend                                                              |
| `secret.yaml`                    | Needed for DB credentials, API keys                           | Usually not needed for frontend, or values are injected at build                          |
| `task-api-deployment.yaml`       | Runs the backend Node.js service                              | Frontend has its own deployment, often using NGINX                                        |
| `task-api-service.yaml`          | Exposes backend to other services                             | Frontend also has a service for Ingress to route traffic to it                            |

This Kubernetes configuration provides a complete, production-ready deployment with high availability, auto-scaling, and proper resource management.

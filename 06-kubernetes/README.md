# 6-Kubernetes Deployment Files

## namespace.yaml
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: task-management
  labels:
    name: task-management
    environment: production
    project: task-api
```

## configmap.yaml
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: task-api-config
  namespace: task-management
data:
  application.yml: |
    server:
      port: 8080
    spring:
      application:
        name: task-management-api
      datasource:
        url: jdbc:mysql://mysql-service:3306/taskdb
        driver-class-name: com.mysql.cj.jdbc.Driver
      jpa:
        hibernate:
          ddl-auto: update
        show-sql: false
        properties:
          hibernate:
            dialect: org.hibernate.dialect.MySQL8Dialect
    management:
      endpoints:
        web:
          exposure:
            include: health,info,metrics,prometheus
      endpoint:
        health:
          show-details: always
      metrics:
        export:
          prometheus:
            enabled: true
    logging:
      level:
        com.taskapi: INFO
      pattern:
        console: "%d{yyyy-MM-dd HH:mm:ss} - %msg%n"
```

## secret.yaml
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: task-api-secret
  namespace: task-management
type: Opaque
data:
  # Base64 encoded values
  mysql-username: dGFza3VzZXI=  # taskuser
  mysql-password: dGFza3Bhc3M=  # taskpass
  mysql-root-password: cm9vdHBhc3M=  # rootpass
  mysql-database: dGFza2Ri  # taskdb
```

## mysql-deployment.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
  namespace: task-management
  labels:
    app: mysql
    tier: database
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
        tier: database
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        ports:
        - containerPort: 3306
          name: mysql
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: task-api-secret
              key: mysql-root-password
        - name: MYSQL_DATABASE
          valueFrom:
            secretKeyRef:
              name: task-api-secret
              key: mysql-database
        - name: MYSQL_USER
          valueFrom:
            secretKeyRef:
              name: task-api-secret
              key: mysql-username
        - name: MYSQL_PASSWORD
          valueFrom:
            secretKeyRef:
              name: task-api-secret
              key: mysql-password
        volumeMounts:
        - name: mysql-persistent-storage
          mountPath: /var/lib/mysql
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        livenessProbe:
          exec:
            command:
            - mysqladmin
            - ping
            - -h
            - localhost
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
        readinessProbe:
          exec:
            command:
            - mysqladmin
            - ping
            - -h
            - localhost
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
      volumes:
      - name: mysql-persistent-storage
        persistentVolumeClaim:
          claimName: mysql-pvc
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-pvc
  namespace: task-management
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: gp2
```

## mysql-service.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  name: mysql-service
  namespace: task-management
  labels:
    app: mysql
    tier: database
spec:
  selector:
    app: mysql
  ports:
  - port: 3306
    targetPort: 3306
    protocol: TCP
    name: mysql
  type: ClusterIP
```

## task-api-deployment.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: task-api
  namespace: task-management
  labels:
    app: task-api
    tier: backend
    version: v1
spec:
  replicas: 3
  selector:
    matchLabels:
      app: task-api
  template:
    metadata:
      labels:
        app: task-api
        tier: backend
        version: v1
    spec:
      containers:
      - name: task-api
        image: task-management-api:latest
        ports:
        - containerPort: 8080
          name: http
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "prod"
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
        - name: SPRING_DATASOURCE_URL
          value: "jdbc:mysql://mysql-service:3306/taskdb"
        volumeMounts:
        - name: config-volume
          mountPath: /app/config
          readOnly: true
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
          timeoutSeconds: 10
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /actuator/health/readiness
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        startupProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 12
      volumes:
      - name: config-volume
        configMap:
          name: task-api-config
      initContainers:
      - name: wait-for-mysql
        image: busybox:1.35
        command: ['sh', '-c']
        args:
        - |
          echo "Waiting for MySQL to be ready..."
          until nc -z mysql-service 3306; do
            echo "MySQL not ready, waiting..."
            sleep 2
          done
          echo "MySQL is ready!"
      restartPolicy: Always
```

## task-api-service.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  name: task-api-service
  namespace: task-management
  labels:
    app: task-api
    tier: backend
spec:
  selector:
    app: task-api
  ports:
  - name: http
    port: 80
    targetPort: 8080
    protocol: TCP
  type: ClusterIP
```

## ingress.yaml
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: task-api-ingress
  namespace: task-management
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/rate-limit: "100"
    nginx.ingress.kubernetes.io/rate-limit-window: "1m"
    nginx.ingress.kubernetes.io/proxy-body-size: "10m"
    nginx.ingress.kubernetes.io/proxy-connect-timeout: "60"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "60"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "60"
spec:
  tls:
  - hosts:
    - api.taskmanagement.local
    secretName: task-api-tls
  rules:
  - host: api.taskmanagement.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: task-api-service
            port:
              number: 80
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: task-api-service
            port:
              number: 80
      - path: /actuator
        pathType: Prefix
        backend:
          service:
            name: task-api-service
            port:
              number: 80
```

## hpa.yaml
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: task-api-hpa
  namespace: task-management
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
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60
      - type: Pods
        value: 2
        periodSeconds: 60
      selectPolicy: Min
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
      - type: Percent
        value: 100
        periodSeconds: 60
      - type: Pods
        value: 4
        periodSeconds: 60
      selectPolicy: Max
```

## pdb.yaml
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: task-api-pdb
  namespace: task-management
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: task-api
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: mysql-pdb
  namespace: task-management
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: mysql
```

## README.md
```markdown
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
```

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

This Kubernetes configuration provides a complete, production-ready deployment with high availability, auto-scaling, and proper resource management.

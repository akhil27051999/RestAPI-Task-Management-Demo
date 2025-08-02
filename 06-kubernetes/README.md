# Section 6: Kubernetes Deployment

## Overview
This section covers complete Kubernetes deployment for the Task Management API including manifests, services, ingress configuration, and deployment strategies.

## Directory Structure
```
6-kubernetes-deployment/
├── manifests/
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── mysql-deployment.yaml
│   ├── mysql-service.yaml
│   ├── mysql-pvc.yaml
│   ├── app-deployment.yaml
│   ├── app-service.yaml
│   ├── app-hpa.yaml
│   └── ingress.yaml
├── helm-chart/
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── values-dev.yaml
│   ├── values-prod.yaml
│   └── templates/
│       ├── deployment.yaml
│       ├── service.yaml
│       ├── configmap.yaml
│       ├── secret.yaml
│       ├── hpa.yaml
│       └── ingress.yaml
├── kustomize/
│   ├── base/
│   │   ├── kustomization.yaml
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── configmap.yaml
│   ├── overlays/
│   │   ├── dev/
│   │   │   ├── kustomization.yaml
│   │   │   └── replica-patch.yaml
│   │   └── prod/
│   │       ├── kustomization.yaml
│   │       ├── replica-patch.yaml
│   │       └── resource-patch.yaml
└── scripts/
    ├── deploy.sh
    ├── rollback.sh
    ├── scale.sh
    └── health-check.sh
```

## Kubernetes Manifests

### 1. Namespace Configuration
```yaml
# manifests/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: task-management
  labels:
    name: task-management
    environment: production
```

### 2. ConfigMap
```yaml
# manifests/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: task-app-config
  namespace: task-management
data:
  application.properties: |
    server.port=8080
    spring.application.name=task-management-api
    
    # Database Configuration
    spring.datasource.url=jdbc:mysql://mysql-service:3306/taskdb
    spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver
    spring.jpa.hibernate.ddl-auto=update
    spring.jpa.show-sql=false
    spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.MySQL8Dialect
    
    # Logging
    logging.level.com.taskmanagement=INFO
    logging.pattern.console=%d{yyyy-MM-dd HH:mm:ss} - %msg%n
    
    # Management endpoints
    management.endpoints.web.exposure.include=health,info,metrics,prometheus
    management.endpoint.health.show-details=always
    management.metrics.export.prometheus.enabled=true
```

### 3. Secret Configuration
```yaml
# manifests/secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: task-app-secret
  namespace: task-management
type: Opaque
data:
  # Base64 encoded values
  mysql-username: cm9vdA==  # root
  mysql-password: cGFzc3dvcmQxMjM=  # password123
  jwt-secret: bXlTZWNyZXRLZXlGb3JKV1Q=  # mySecretKeyForJWT
```

### 4. MySQL Persistent Volume Claim
```yaml
# manifests/mysql-pvc.yaml
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

### 5. MySQL Deployment
```yaml
# manifests/mysql-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
  namespace: task-management
  labels:
    app: mysql
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        ports:
        - containerPort: 3306
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: task-app-secret
              key: mysql-password
        - name: MYSQL_DATABASE
          value: taskdb
        volumeMounts:
        - name: mysql-storage
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
        readinessProbe:
          exec:
            command:
            - mysqladmin
            - ping
            - -h
            - localhost
          initialDelaySeconds: 5
          periodSeconds: 5
      volumes:
      - name: mysql-storage
        persistentVolumeClaim:
          claimName: mysql-pvc
```

### 6. MySQL Service
```yaml
# manifests/mysql-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: mysql-service
  namespace: task-management
  labels:
    app: mysql
spec:
  selector:
    app: mysql
  ports:
  - port: 3306
    targetPort: 3306
  type: ClusterIP
```

### 7. Application Deployment
```yaml
# manifests/app-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: task-management-api
  namespace: task-management
  labels:
    app: task-management-api
    version: v1
spec:
  replicas: 3
  selector:
    matchLabels:
      app: task-management-api
  template:
    metadata:
      labels:
        app: task-management-api
        version: v1
    spec:
      containers:
      - name: task-management-api
        image: <AWS_ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/task-management-api:latest
        ports:
        - containerPort: 8080
        env:
        - name: SPRING_DATASOURCE_USERNAME
          valueFrom:
            secretKeyRef:
              name: task-app-secret
              key: mysql-username
        - name: SPRING_DATASOURCE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: task-app-secret
              key: mysql-password
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: task-app-secret
              key: jwt-secret
        volumeMounts:
        - name: config-volume
          mountPath: /app/config
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
        startupProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
          failureThreshold: 10
      volumes:
      - name: config-volume
        configMap:
          name: task-app-config
      initContainers:
      - name: wait-for-mysql
        image: busybox:1.35
        command: ['sh', '-c', 'until nc -z mysql-service 3306; do echo waiting for mysql; sleep 2; done;']
```

### 8. Application Service
```yaml
# manifests/app-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: task-management-service
  namespace: task-management
  labels:
    app: task-management-api
spec:
  selector:
    app: task-management-api
  ports:
  - name: http
    port: 80
    targetPort: 8080
    protocol: TCP
  type: ClusterIP
```

### 9. Horizontal Pod Autoscaler
```yaml
# manifests/app-hpa.yaml
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
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
      - type: Percent
        value: 100
        periodSeconds: 60
```

### 10. Ingress Configuration
```yaml
# manifests/ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: task-management-ingress
  namespace: task-management
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/rate-limit: "100"
    nginx.ingress.kubernetes.io/rate-limit-window: "1m"
spec:
  tls:
  - hosts:
    - api.taskmanagement.com
    secretName: task-management-tls
  rules:
  - host: api.taskmanagement.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: task-management-service
            port:
              number: 80
```

## Helm Chart Configuration

### Chart.yaml
```yaml
# helm-chart/Chart.yaml
apiVersion: v2
name: task-management-api
description: A Helm chart for Task Management API
type: application
version: 0.1.0
appVersion: "1.0.0"
keywords:
  - task-management
  - spring-boot
  - mysql
home: https://github.com/your-org/task-management-api
sources:
  - https://github.com/your-org/task-management-api
maintainers:
  - name: DevOps Team
    email: devops@company.com
```

### Values.yaml
```yaml
# helm-chart/values.yaml
replicaCount: 3

image:
  repository: <AWS_ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/task-management-api
  pullPolicy: IfNotPresent
  tag: "latest"

nameOverride: ""
fullnameOverride: ""

service:
  type: ClusterIP
  port: 80
  targetPort: 8080

ingress:
  enabled: true
  className: "nginx"
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
  hosts:
    - host: api.taskmanagement.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: task-management-tls
      hosts:
        - api.taskmanagement.com

resources:
  limits:
    cpu: 500m
    memory: 1Gi
  requests:
    cpu: 250m
    memory: 512Mi

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 80

mysql:
  enabled: true
  image:
    repository: mysql
    tag: "8.0"
  persistence:
    enabled: true
    size: 10Gi
    storageClass: gp2
  resources:
    limits:
      cpu: 500m
      memory: 1Gi
    requests:
      cpu: 250m
      memory: 512Mi

config:
  database:
    name: taskdb
  logging:
    level: INFO

secrets:
  mysql:
    username: root
    password: password123
  jwt:
    secret: mySecretKeyForJWT
```

## Deployment Scripts

### Deploy Script
```bash
#!/bin/bash
# scripts/deploy.sh

set -e

NAMESPACE="task-management"
ENVIRONMENT=${1:-dev}

echo "🚀 Deploying Task Management API to $ENVIRONMENT environment..."

# Create namespace if it doesn't exist
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Apply manifests
echo "📦 Applying Kubernetes manifests..."
kubectl apply -f manifests/ -n $NAMESPACE

# Wait for MySQL to be ready
echo "⏳ Waiting for MySQL to be ready..."
kubectl wait --for=condition=ready pod -l app=mysql -n $NAMESPACE --timeout=300s

# Wait for application to be ready
echo "⏳ Waiting for application to be ready..."
kubectl wait --for=condition=ready pod -l app=task-management-api -n $NAMESPACE --timeout=300s

# Check deployment status
echo "✅ Deployment Status:"
kubectl get pods -n $NAMESPACE
kubectl get services -n $NAMESPACE
kubectl get ingress -n $NAMESPACE

echo "🎉 Deployment completed successfully!"
```

### Health Check Script
```bash
#!/bin/bash
# scripts/health-check.sh

NAMESPACE="task-management"
SERVICE_URL="http://api.taskmanagement.com"

echo "🔍 Performing health checks..."

# Check pod status
echo "📊 Pod Status:"
kubectl get pods -n $NAMESPACE

# Check service endpoints
echo "🔗 Service Endpoints:"
kubectl get endpoints -n $NAMESPACE

# Health check via API
echo "🏥 API Health Check:"
if curl -f -s "$SERVICE_URL/actuator/health" > /dev/null; then
    echo "✅ API is healthy"
    curl -s "$SERVICE_URL/actuator/health" | jq .
else
    echo "❌ API health check failed"
    exit 1
fi

# Check metrics endpoint
echo "📈 Metrics Endpoint:"
if curl -f -s "$SERVICE_URL/actuator/metrics" > /dev/null; then
    echo "✅ Metrics endpoint is accessible"
else
    echo "❌ Metrics endpoint check failed"
fi

echo "🎉 All health checks passed!"
```

### Scale Script
```bash
#!/bin/bash
# scripts/scale.sh

NAMESPACE="task-management"
REPLICAS=${1:-3}

echo "📈 Scaling Task Management API to $REPLICAS replicas..."

kubectl scale deployment task-management-api --replicas=$REPLICAS -n $NAMESPACE

echo "⏳ Waiting for scaling to complete..."
kubectl rollout status deployment/task-management-api -n $NAMESPACE

echo "📊 Current pod status:"
kubectl get pods -n $NAMESPACE -l app=task-management-api

echo "✅ Scaling completed!"
```

### Rollback Script
```bash
#!/bin/bash
# scripts/rollback.sh

NAMESPACE="task-management"
REVISION=${1:-}

echo "🔄 Rolling back Task Management API deployment..."

if [ -n "$REVISION" ]; then
    kubectl rollout undo deployment/task-management-api --to-revision=$REVISION -n $NAMESPACE
    echo "📝 Rolling back to revision $REVISION"
else
    kubectl rollout undo deployment/task-management-api -n $NAMESPACE
    echo "📝 Rolling back to previous revision"
fi

echo "⏳ Waiting for rollback to complete..."
kubectl rollout status deployment/task-management-api -n $NAMESPACE

echo "📊 Rollout history:"
kubectl rollout history deployment/task-management-api -n $NAMESPACE

echo "✅ Rollback completed!"
```

## Kustomize Configuration

### Base Kustomization
```yaml
# kustomize/base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../manifests/namespace.yaml
  - ../../manifests/configmap.yaml
  - ../../manifests/secret.yaml
  - ../../manifests/mysql-pvc.yaml
  - ../../manifests/mysql-deployment.yaml
  - ../../manifests/mysql-service.yaml
  - ../../manifests/app-deployment.yaml
  - ../../manifests/app-service.yaml
  - ../../manifests/app-hpa.yaml
  - ../../manifests/ingress.yaml

commonLabels:
  app.kubernetes.io/name: task-management-api
  app.kubernetes.io/part-of: task-management-system

images:
  - name: task-management-api
    newName: <AWS_ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/task-management-api
    newTag: latest
```

### Development Overlay
```yaml
# kustomize/overlays/dev/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../base

namePrefix: dev-

commonLabels:
  environment: development

patches:
  - replica-patch.yaml

images:
  - name: task-management-api
    newTag: dev-latest
```

```yaml
# kustomize/overlays/dev/replica-patch.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: task-management-api
spec:
  replicas: 1
```

## Deployment Strategies

### 1. Rolling Update (Default)
```yaml
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 25%
      maxSurge: 25%
```

### 2. Blue-Green Deployment
```bash
# Blue-Green deployment script
#!/bin/bash

NAMESPACE="task-management"
NEW_VERSION=$1
CURRENT_COLOR=$(kubectl get service task-management-service -n $NAMESPACE -o jsonpath='{.spec.selector.color}')
NEW_COLOR=$([ "$CURRENT_COLOR" = "blue" ] && echo "green" || echo "blue")

echo "Current color: $CURRENT_COLOR, New color: $NEW_COLOR"

# Deploy new version with new color
kubectl set image deployment/task-management-api-$NEW_COLOR task-management-api=<ECR_REPO>:$NEW_VERSION -n $NAMESPACE

# Wait for new deployment
kubectl rollout status deployment/task-management-api-$NEW_COLOR -n $NAMESPACE

# Switch traffic
kubectl patch service task-management-service -n $NAMESPACE -p '{"spec":{"selector":{"color":"'$NEW_COLOR'"}}}'

echo "Traffic switched to $NEW_COLOR"
```

### 3. Canary Deployment
```yaml
# Canary service configuration
apiVersion: v1
kind: Service
metadata:
  name: task-management-canary
spec:
  selector:
    app: task-management-api
    version: canary
  ports:
  - port: 80
    targetPort: 8080
```

## Monitoring and Observability

### ServiceMonitor for Prometheus
```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: task-management-metrics
  namespace: task-management
spec:
  selector:
    matchLabels:
      app: task-management-api
  endpoints:
  - port: http
    path: /actuator/prometheus
    interval: 30s
```

## Security Best Practices

### 1. Pod Security Policy
```yaml
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: task-management-psp
spec:
  privileged: false
  allowPrivilegeEscalation: false
  requiredDropCapabilities:
    - ALL
  volumes:
    - 'configMap'
    - 'emptyDir'
    - 'projected'
    - 'secret'
    - 'downwardAPI'
    - 'persistentVolumeClaim'
  runAsUser:
    rule: 'MustRunAsNonRoot'
  seLinux:
    rule: 'RunAsAny'
  fsGroup:
    rule: 'RunAsAny'
```

### 2. Network Policy
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: task-management-netpol
  namespace: task-management
spec:
  podSelector:
    matchLabels:
      app: task-management-api
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: mysql
    ports:
    - protocol: TCP
      port: 3306
```

## Troubleshooting Guide

### Common Issues and Solutions

1. **Pod CrashLoopBackOff**
   ```bash
   kubectl logs -f deployment/task-management-api -n task-management
   kubectl describe pod <pod-name> -n task-management
   ```

2. **Database Connection Issues**
   ```bash
   kubectl exec -it deployment/mysql -n task-management -- mysql -u root -p
   kubectl port-forward service/mysql-service 3306:3306 -n task-management
   ```

3. **Ingress Not Working**
   ```bash
   kubectl get ingress -n task-management
   kubectl describe ingress task-management-ingress -n task-management
   ```

## Next Steps

After completing this section, you'll have:
- ✅ Complete Kubernetes manifests for production deployment
- ✅ Helm charts for package management
- ✅ Kustomize configurations for environment-specific deployments
- ✅ Deployment automation scripts
- ✅ Health checking and monitoring setup
- ✅ Security policies and network controls

**Ready for Section 7: CI/CD Pipeline** - GitHub Actions workflows and ArgoCD GitOps setup for automated deployments.

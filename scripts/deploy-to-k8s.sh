#!/bin/bash

# Task Management System - Kubernetes Deployment Script

set -e

NAMESPACE="task-management"
REGISTRY="your-registry"
VERSION=${1:-"latest"}

echo "🚀 Deploying Task Management System to Kubernetes..."
echo "📦 Version: $VERSION"
echo "🏷️ Namespace: $NAMESPACE"

# Build and push images
build_and_push() {
    echo "🔨 Building and pushing images..."
    
    # Build backend
    echo "Building backend image..."
    cd 2-source-code
    docker build -t $REGISTRY/task-management-api:$VERSION .
    docker push $REGISTRY/task-management-api:$VERSION
    cd ..
    
    # Build frontend
    echo "Building frontend image..."
    cd 3-frontend
    docker build -t $REGISTRY/task-management-frontend:$VERSION .
    docker push $REGISTRY/task-management-frontend:$VERSION
    cd ..
    
    echo "✅ Images built and pushed"
}

# Deploy database
deploy_database() {
    echo "🗄️ Deploying MySQL database..."
    
    kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
  namespace: $NAMESPACE
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
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: "rootpassword"
        - name: MYSQL_DATABASE
          value: "taskdb"
        - name: MYSQL_USER
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: username
        - name: MYSQL_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: password
        ports:
        - containerPort: 3306
        volumeMounts:
        - name: mysql-storage
          mountPath: /var/lib/mysql
      volumes:
      - name: mysql-storage
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: mysql-service
  namespace: $NAMESPACE
spec:
  selector:
    app: mysql
  ports:
    - port: 3306
      targetPort: 3306
EOF
    
    echo "✅ MySQL deployed"
}

# Deploy backend
deploy_backend() {
    echo "⚙️ Deploying backend API..."
    
    # Update image tag in deployment
    sed -i "s|task-management-api:latest|$REGISTRY/task-management-api:$VERSION|g" 7-kubernetes/task-api-deployment.yaml
    
    kubectl apply -f 7-kubernetes/task-api-deployment.yaml -n $NAMESPACE
    kubectl apply -f 7-kubernetes/task-api-service.yaml -n $NAMESPACE
    
    echo "✅ Backend deployed"
}

# Deploy frontend
deploy_frontend() {
    echo "🌐 Deploying frontend..."
    
    # Update image tag in deployment
    sed -i "s|task-management-frontend:latest|$REGISTRY/task-management-frontend:$VERSION|g" 7-kubernetes/frontend-deployment.yaml
    
    kubectl apply -f 7-kubernetes/frontend-deployment.yaml -n $NAMESPACE
    kubectl apply -f 7-kubernetes/frontend-service.yaml -n $NAMESPACE
    
    echo "✅ Frontend deployed"
}

# Deploy ingress
deploy_ingress() {
    echo "🌍 Deploying ingress..."
    
    kubectl apply -f 7-kubernetes/ingress.yaml -n $NAMESPACE
    
    echo "✅ Ingress deployed"
}

# Deploy monitoring
deploy_monitoring() {
    echo "📊 Deploying monitoring stack..."
    
    kubectl apply -f 9-monitoring/prometheus/ -n $NAMESPACE
    kubectl apply -f 9-monitoring/grafana/ -n $NAMESPACE
    
    echo "✅ Monitoring deployed"
}

# Wait for deployments
wait_for_deployments() {
    echo "⏳ Waiting for deployments to be ready..."
    
    kubectl wait --for=condition=available --timeout=300s deployment/mysql -n $NAMESPACE
    kubectl wait --for=condition=available --timeout=300s deployment/task-backend -n $NAMESPACE
    kubectl wait --for=condition=available --timeout=300s deployment/task-frontend -n $NAMESPACE
    
    echo "✅ All deployments ready"
}

# Show status
show_status() {
    echo ""
    echo "📋 Deployment Status:"
    kubectl get pods -n $NAMESPACE
    echo ""
    kubectl get svc -n $NAMESPACE
    echo ""
    kubectl get ingress -n $NAMESPACE
    echo ""
    
    # Get ingress IP
    INGRESS_IP=$(kubectl get ingress task-management-ingress -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    if [ ! -z "$INGRESS_IP" ]; then
        echo "🌐 Access your application at: http://$INGRESS_IP"
    else
        echo "🌐 Ingress IP pending... Check with: kubectl get ingress -n $NAMESPACE"
    fi
}

# Rollback function
rollback() {
    echo "🔄 Rolling back deployment..."
    kubectl rollout undo deployment/task-backend -n $NAMESPACE
    kubectl rollout undo deployment/task-frontend -n $NAMESPACE
    echo "✅ Rollback complete"
}

# Main execution
main() {
    case "${1:-deploy}" in
        "deploy")
            build_and_push
            deploy_database
            deploy_backend
            deploy_frontend
            deploy_ingress
            deploy_monitoring
            wait_for_deployments
            show_status
            ;;
        "rollback")
            rollback
            ;;
        "status")
            show_status
            ;;
        *)
            echo "Usage: $0 [deploy|rollback|status] [version]"
            exit 1
            ;;
    esac
}

main "$@"

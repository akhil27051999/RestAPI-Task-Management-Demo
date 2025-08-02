# Scripts Files

## setup-environment.sh
```bash
#!/bin/bash

set -e

PROJECT_NAME="task-management-api"
NAMESPACE="task-management"

echo "🚀 Setting up environment for $PROJECT_NAME..."

# Check prerequisites
check_prerequisites() {
    echo "✅ Checking prerequisites..."
    
    command -v kubectl >/dev/null 2>&1 || { echo "❌ kubectl is required"; exit 1; }
    command -v docker >/dev/null 2>&1 || { echo "❌ docker is required"; exit 1; }
    command -v helm >/dev/null 2>&1 || { echo "❌ helm is required"; exit 1; }
    
    echo "✅ All prerequisites met"
}

# Setup Kubernetes cluster
setup_cluster() {
    echo "🔧 Setting up Kubernetes cluster..."
    
    # Check if cluster is accessible
    if ! kubectl cluster-info >/dev/null 2>&1; then
        echo "❌ Kubernetes cluster not accessible"
        echo "Please ensure kubectl is configured and cluster is running"
        exit 1
    fi
    
    echo "✅ Kubernetes cluster is accessible"
}

# Create namespaces
create_namespaces() {
    echo "📦 Creating namespaces..."
    
    kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
    kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
    kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
    
    echo "✅ Namespaces created"
}

# Setup NGINX Ingress Controller
setup_ingress() {
    echo "🌐 Setting up NGINX Ingress Controller..."
    
    if ! kubectl get namespace ingress-nginx >/dev/null 2>&1; then
        kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
        
        echo "⏳ Waiting for ingress controller to be ready..."
        kubectl wait --namespace ingress-nginx \
            --for=condition=ready pod \
            --selector=app.kubernetes.io/component=controller \
            --timeout=300s
    fi
    
    echo "✅ NGINX Ingress Controller ready"
}

# Setup cert-manager
setup_cert_manager() {
    echo "🔒 Setting up cert-manager..."
    
    if ! kubectl get namespace cert-manager >/dev/null 2>&1; then
        kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
        
        echo "⏳ Waiting for cert-manager to be ready..."
        kubectl wait --namespace cert-manager \
            --for=condition=ready pod \
            --selector=app.kubernetes.io/instance=cert-manager \
            --timeout=300s
    fi
    
    echo "✅ cert-manager ready"
}

# Setup monitoring stack
setup_monitoring() {
    echo "📊 Setting up monitoring stack..."
    
    # Add Helm repositories
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo update
    
    # Install Prometheus
    if ! helm list -n monitoring | grep -q prometheus; then
        helm install prometheus prometheus-community/kube-prometheus-stack \
            --namespace monitoring \
            --create-namespace \
            --set grafana.adminPassword=admin123 \
            --wait
    fi
    
    echo "✅ Monitoring stack ready"
}

# Setup ArgoCD
setup_argocd() {
    echo "🔄 Setting up ArgoCD..."
    
    if ! kubectl get deployment argocd-server -n argocd >/dev/null 2>&1; then
        kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
        
        echo "⏳ Waiting for ArgoCD to be ready..."
        kubectl wait --namespace argocd \
            --for=condition=available deployment \
            --selector=app.kubernetes.io/part-of=argocd \
            --timeout=300s
    fi
    
    echo "✅ ArgoCD ready"
    echo "🔑 ArgoCD admin password:"
    kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
    echo ""
}

# Create secrets
create_secrets() {
    echo "🔐 Creating secrets..."
    
    # Database secret
    kubectl create secret generic task-api-secret \
        --from-literal=mysql-username=taskuser \
        --from-literal=mysql-password=taskpass \
        --from-literal=mysql-root-password=rootpass \
        --from-literal=mysql-database=taskdb \
        --namespace $NAMESPACE \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Grafana secret
    kubectl create secret generic grafana-secret \
        --from-literal=admin-password=admin123 \
        --namespace monitoring \
        --dry-run=client -o yaml | kubectl apply -f -
    
    echo "✅ Secrets created"
}

# Setup storage classes
setup_storage() {
    echo "💾 Setting up storage classes..."
    
    # Check if gp2 storage class exists
    if ! kubectl get storageclass gp2 >/dev/null 2>&1; then
        cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp2
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp2
  fsType: ext4
allowVolumeExpansion: true
EOF
    fi
    
    echo "✅ Storage classes ready"
}

# Main execution
main() {
    echo "🎯 Starting environment setup for $PROJECT_NAME"
    
    check_prerequisites
    setup_cluster
    create_namespaces
    setup_ingress
    setup_cert_manager
    setup_monitoring
    setup_argocd
    create_secrets
    setup_storage
    
    echo ""
    echo "🎉 Environment setup completed successfully!"
    echo ""
    echo "📋 Summary:"
    echo "  ✅ Kubernetes cluster ready"
    echo "  ✅ Namespaces: $NAMESPACE, monitoring, argocd"
    echo "  ✅ NGINX Ingress Controller installed"
    echo "  ✅ cert-manager installed"
    echo "  ✅ Prometheus & Grafana installed"
    echo "  ✅ ArgoCD installed"
    echo "  ✅ Secrets created"
    echo "  ✅ Storage classes configured"
    echo ""
    echo "🌐 Access URLs:"
    echo "  📊 Grafana: kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring"
    echo "  🔄 ArgoCD: kubectl port-forward svc/argocd-server 8080:443 -n argocd"
    echo ""
    echo "🔑 Default Credentials:"
    echo "  📊 Grafana: admin/admin123"
    echo "  🔄 ArgoCD: admin/$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"
    echo ""
    echo "🚀 Ready to deploy applications!"
}

# Execute main function
main "$@"
```

## deploy-to-k8s.sh
```bash
#!/bin/bash

set -e

PROJECT_NAME="task-management-api"
NAMESPACE="task-management"
ENVIRONMENT=${1:-dev}

echo "🚀 Deploying $PROJECT_NAME to Kubernetes ($ENVIRONMENT environment)..."

# Validate environment
validate_environment() {
    if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
        echo "❌ Invalid environment. Use: dev, staging, or prod"
        exit 1
    fi
    
    echo "✅ Environment: $ENVIRONMENT"
}

# Check prerequisites
check_prerequisites() {
    echo "✅ Checking prerequisites..."
    
    command -v kubectl >/dev/null 2>&1 || { echo "❌ kubectl is required"; exit 1; }
    
    # Check if cluster is accessible
    if ! kubectl cluster-info >/dev/null 2>&1; then
        echo "❌ Kubernetes cluster not accessible"
        exit 1
    fi
    
    # Check if namespace exists
    if ! kubectl get namespace $NAMESPACE >/dev/null 2>&1; then
        echo "❌ Namespace $NAMESPACE does not exist. Run setup-environment.sh first."
        exit 1
    fi
    
    echo "✅ Prerequisites met"
}

# Update image tags based on environment
update_image_tags() {
    echo "🏷️ Updating image tags for $ENVIRONMENT..."
    
    case $ENVIRONMENT in
        dev)
            IMAGE_TAG="dev-latest"
            REPLICAS=1
            ;;
        staging)
            IMAGE_TAG="staging-latest"
            REPLICAS=2
            ;;
        prod)
            IMAGE_TAG="latest"
            REPLICAS=3
            ;;
    esac
    
    # Update deployment manifest
    if [ -f "k8s/task-api-deployment.yaml" ]; then
        sed -i.bak "s|image: .*task-management-api:.*|image: task-management-api:$IMAGE_TAG|g" k8s/task-api-deployment.yaml
        sed -i.bak "s|replicas: .*|replicas: $REPLICAS|g" k8s/task-api-deployment.yaml
    fi
    
    echo "✅ Image tags updated: $IMAGE_TAG, Replicas: $REPLICAS"
}

# Deploy database
deploy_database() {
    echo "🗄️ Deploying database..."
    
    # Apply database manifests
    kubectl apply -f k8s/mysql-deployment.yaml -n $NAMESPACE
    kubectl apply -f k8s/mysql-service.yaml -n $NAMESPACE
    
    # Wait for database to be ready
    echo "⏳ Waiting for database to be ready..."
    kubectl wait --for=condition=ready pod -l app=mysql -n $NAMESPACE --timeout=300s
    
    echo "✅ Database deployed and ready"
}

# Deploy application
deploy_application() {
    echo "📱 Deploying application..."
    
    # Apply application manifests
    kubectl apply -f k8s/configmap.yaml -n $NAMESPACE
    kubectl apply -f k8s/secret.yaml -n $NAMESPACE
    kubectl apply -f k8s/task-api-deployment.yaml -n $NAMESPACE
    kubectl apply -f k8s/task-api-service.yaml -n $NAMESPACE
    
    # Wait for application to be ready
    echo "⏳ Waiting for application to be ready..."
    kubectl wait --for=condition=ready pod -l app=task-api -n $NAMESPACE --timeout=300s
    
    echo "✅ Application deployed and ready"
}

# Deploy ingress and scaling
deploy_ingress_scaling() {
    echo "🌐 Deploying ingress and scaling..."
    
    # Apply ingress and scaling manifests
    kubectl apply -f k8s/ingress.yaml -n $NAMESPACE
    
    if [ "$ENVIRONMENT" = "prod" ]; then
        kubectl apply -f k8s/hpa.yaml -n $NAMESPACE
        kubectl apply -f k8s/pdb.yaml -n $NAMESPACE
        echo "✅ HPA and PDB configured for production"
    fi
    
    echo "✅ Ingress and scaling configured"
}

# Verify deployment
verify_deployment() {
    echo "🔍 Verifying deployment..."
    
    # Check all resources
    echo "📋 Deployment status:"
    kubectl get all -n $NAMESPACE
    
    echo ""
    echo "🔗 Services:"
    kubectl get svc -n $NAMESPACE
    
    echo ""
    echo "🌐 Ingress:"
    kubectl get ingress -n $NAMESPACE
    
    # Health check
    echo ""
    echo "🏥 Performing health check..."
    
    # Port forward for health check
    kubectl port-forward svc/task-api-service 8080:80 -n $NAMESPACE &
    PF_PID=$!
    
    sleep 10
    
    if curl -f -s http://localhost:8080/actuator/health >/dev/null; then
        echo "✅ Health check passed"
    else
        echo "⚠️ Health check failed - application may still be starting"
    fi
    
    # Kill port forward
    kill $PF_PID 2>/dev/null || true
    
    echo "✅ Deployment verification completed"
}

# Show access information
show_access_info() {
    echo ""
    echo "🎉 Deployment completed successfully!"
    echo ""
    echo "📋 Access Information:"
    echo "  🌐 Application URL: http://api.taskmanagement.local"
    echo "  🏥 Health Check: http://api.taskmanagement.local/actuator/health"
    echo "  📊 Metrics: http://api.taskmanagement.local/actuator/prometheus"
    echo ""
    echo "🔧 Useful Commands:"
    echo "  📋 View pods: kubectl get pods -n $NAMESPACE"
    echo "  📝 View logs: kubectl logs -f deployment/task-api -n $NAMESPACE"
    echo "  🔗 Port forward: kubectl port-forward svc/task-api-service 8080:80 -n $NAMESPACE"
    echo "  📊 Scale app: kubectl scale deployment task-api --replicas=5 -n $NAMESPACE"
    echo ""
    echo "🧪 Test API:"
    echo "  curl -X POST http://api.taskmanagement.local/api/tasks \\"
    echo "    -H 'Content-Type: application/json' \\"
    echo "    -d '{\"title\":\"Test Task\",\"description\":\"Test Description\"}'"
    echo ""
}

# Rollback function
rollback_deployment() {
    echo "🔄 Rolling back deployment..."
    
    kubectl rollout undo deployment/task-api -n $NAMESPACE
    kubectl rollout undo deployment/mysql -n $NAMESPACE
    
    echo "✅ Rollback completed"
}

# Main execution
main() {
    echo "🎯 Starting deployment to $ENVIRONMENT environment"
    
    validate_environment
    check_prerequisites
    update_image_tags
    deploy_database
    deploy_application
    deploy_ingress_scaling
    verify_deployment
    show_access_info
}

# Handle script arguments
case "${2:-deploy}" in
    deploy)
        main "$@"
        ;;
    rollback)
        rollback_deployment
        ;;
    *)
        echo "Usage: $0 <environment> [deploy|rollback]"
        echo "Environments: dev, staging, prod"
        exit 1
        ;;
esac
```

## cleanup.sh
```bash
#!/bin/bash

set -e

PROJECT_NAME="task-management-api"
NAMESPACE="task-management"
CLEANUP_TYPE=${1:-app}

echo "🧹 Cleaning up $PROJECT_NAME..."

# Cleanup application only
cleanup_application() {
    echo "📱 Cleaning up application resources..."
    
    if kubectl get namespace $NAMESPACE >/dev/null 2>&1; then
        # Delete application resources
        kubectl delete deployment task-api -n $NAMESPACE --ignore-not-found=true
        kubectl delete service task-api-service -n $NAMESPACE --ignore-not-found=true
        kubectl delete configmap task-api-config -n $NAMESPACE --ignore-not-found=true
        kubectl delete secret task-api-secret -n $NAMESPACE --ignore-not-found=true
        kubectl delete ingress task-api-ingress -n $NAMESPACE --ignore-not-found=true
        kubectl delete hpa task-api-hpa -n $NAMESPACE --ignore-not-found=true
        kubectl delete pdb task-api-pdb -n $NAMESPACE --ignore-not-found=true
        
        echo "✅ Application resources cleaned up"
    else
        echo "⚠️ Namespace $NAMESPACE not found"
    fi
}

# Cleanup database
cleanup_database() {
    echo "🗄️ Cleaning up database resources..."
    
    if kubectl get namespace $NAMESPACE >/dev/null 2>&1; then
        # Delete database resources
        kubectl delete deployment mysql -n $NAMESPACE --ignore-not-found=true
        kubectl delete service mysql-service -n $NAMESPACE --ignore-not-found=true
        kubectl delete pvc mysql-pvc -n $NAMESPACE --ignore-not-found=true
        kubectl delete pdb mysql-pdb -n $NAMESPACE --ignore-not-found=true
        
        echo "✅ Database resources cleaned up"
    fi
}

# Cleanup entire namespace
cleanup_namespace() {
    echo "📦 Cleaning up entire namespace..."
    
    if kubectl get namespace $NAMESPACE >/dev/null 2>&1; then
        kubectl delete namespace $NAMESPACE
        echo "✅ Namespace $NAMESPACE deleted"
    else
        echo "⚠️ Namespace $NAMESPACE not found"
    fi
}

# Cleanup monitoring stack
cleanup_monitoring() {
    echo "📊 Cleaning up monitoring stack..."
    
    # Uninstall Prometheus Helm release
    if helm list -n monitoring | grep -q prometheus; then
        helm uninstall prometheus -n monitoring
        echo "✅ Prometheus uninstalled"
    fi
    
    # Delete monitoring namespace
    if kubectl get namespace monitoring >/dev/null 2>&1; then
        kubectl delete namespace monitoring
        echo "✅ Monitoring namespace deleted"
    fi
}

# Cleanup ArgoCD
cleanup_argocd() {
    echo "🔄 Cleaning up ArgoCD..."
    
    if kubectl get namespace argocd >/dev/null 2>&1; then
        kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml --ignore-not-found=true
        kubectl delete namespace argocd --ignore-not-found=true
        echo "✅ ArgoCD cleaned up"
    fi
}

# Cleanup ingress controller
cleanup_ingress() {
    echo "🌐 Cleaning up NGINX Ingress Controller..."
    
    if kubectl get namespace ingress-nginx >/dev/null 2>&1; then
        kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml --ignore-not-found=true
        echo "✅ NGINX Ingress Controller cleaned up"
    fi
}

# Cleanup cert-manager
cleanup_cert_manager() {
    echo "🔒 Cleaning up cert-manager..."
    
    if kubectl get namespace cert-manager >/dev/null 2>&1; then
        kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml --ignore-not-found=true
        echo "✅ cert-manager cleaned up"
    fi
}

# Cleanup persistent volumes
cleanup_volumes() {
    echo "💾 Cleaning up persistent volumes..."
    
    # Delete PVs that are available (not bound)
    kubectl get pv | grep Available | awk '{print $1}' | xargs -r kubectl delete pv
    
    echo "✅ Available persistent volumes cleaned up"
}

# Cleanup Docker images (local)
cleanup_docker_images() {
    echo "🐳 Cleaning up Docker images..."
    
    if command -v docker >/dev/null 2>&1; then
        # Remove project-specific images
        docker images | grep $PROJECT_NAME | awk '{print $3}' | xargs -r docker rmi -f
        
        # Clean up dangling images
        docker image prune -f
        
        echo "✅ Docker images cleaned up"
    else
        echo "⚠️ Docker not found, skipping image cleanup"
    fi
}

# Complete cleanup (everything)
cleanup_all() {
    echo "💥 Performing complete cleanup..."
    
    cleanup_application
    cleanup_database
    cleanup_namespace
    cleanup_monitoring
    cleanup_argocd
    cleanup_ingress
    cleanup_cert_manager
    cleanup_volumes
    cleanup_docker_images
    
    echo "✅ Complete cleanup finished"
}

# Show cleanup options
show_help() {
    echo "Usage: $0 [cleanup-type]"
    echo ""
    echo "Cleanup Types:"
    echo "  app        - Cleanup application resources only (default)"
    echo "  database   - Cleanup database resources"
    echo "  namespace  - Cleanup entire namespace"
    echo "  monitoring - Cleanup monitoring stack"
    echo "  argocd     - Cleanup ArgoCD"
    echo "  ingress    - Cleanup NGINX Ingress Controller"
    echo "  cert-manager - Cleanup cert-manager"
    echo "  volumes    - Cleanup persistent volumes"
    echo "  docker     - Cleanup Docker images"
    echo "  all        - Complete cleanup (everything)"
    echo "  help       - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 app              # Cleanup application only"
    echo "  $0 namespace        # Delete entire namespace"
    echo "  $0 all              # Complete cleanup"
}

# Confirmation prompt
confirm_cleanup() {
    echo "⚠️ WARNING: This will delete resources for $PROJECT_NAME"
    echo "Cleanup type: $CLEANUP_TYPE"
    echo ""
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Cleanup cancelled"
        exit 0
    fi
}

# Main execution
main() {
    case $CLEANUP_TYPE in
        app)
            confirm_cleanup
            cleanup_application
            ;;
        database)
            confirm_cleanup
            cleanup_database
            ;;
        namespace)
            confirm_cleanup
            cleanup_namespace
            ;;
        monitoring)
            confirm_cleanup
            cleanup_monitoring
            ;;
        argocd)
            confirm_cleanup
            cleanup_argocd
            ;;
        ingress)
            confirm_cleanup
            cleanup_ingress
            ;;
        cert-manager)
            confirm_cleanup
            cleanup_cert_manager
            ;;
        volumes)
            confirm_cleanup
            cleanup_volumes
            ;;
        docker)
            confirm_cleanup
            cleanup_docker_images
            ;;
        all)
            confirm_cleanup
            cleanup_all
            ;;
        help)
            show_help
            ;;
        *)
            echo "❌ Invalid cleanup type: $CLEANUP_TYPE"
            show_help
            exit 1
            ;;
    esac
    
    echo ""
    echo "🎉 Cleanup completed successfully!"
}

# Execute main function
main "$@"
```

## Usage Instructions

### Make Scripts Executable
```bash
chmod +x scripts/*.sh
```

### Setup Environment
```bash
# Setup complete environment
./scripts/setup-environment.sh
```

### Deploy Application
```bash
# Deploy to development
./scripts/deploy-to-k8s.sh dev

# Deploy to staging
./scripts/deploy-to-k8s.sh staging

# Deploy to production
./scripts/deploy-to-k8s.sh prod

# Rollback deployment
./scripts/deploy-to-k8s.sh prod rollback
```

### Cleanup Resources
```bash
# Cleanup application only
./scripts/cleanup.sh app

# Cleanup entire namespace
./scripts/cleanup.sh namespace

# Complete cleanup
./scripts/cleanup.sh all

# Show help
./scripts/cleanup.sh help
```

## Script Features

### setup-environment.sh
✅ **Complete Environment Setup** - Kubernetes, ingress, monitoring, ArgoCD
✅ **Prerequisite Checking** - Validates required tools
✅ **Automated Installation** - Installs all required components
✅ **Secret Management** - Creates necessary secrets
✅ **Storage Configuration** - Sets up storage classes

### deploy-to-k8s.sh
✅ **Multi-Environment Support** - Dev, staging, production deployments
✅ **Image Tag Management** - Environment-specific image tags
✅ **Health Verification** - Automated health checks
✅ **Rollback Support** - Easy rollback functionality
✅ **Access Information** - Shows URLs and useful commands

### cleanup.sh
✅ **Granular Cleanup** - Selective resource cleanup
✅ **Safety Confirmations** - Prevents accidental deletions
✅ **Complete Cleanup** - Option to remove everything
✅ **Docker Integration** - Cleans up local Docker images

These scripts provide complete automation for environment setup, deployment, and cleanup of the Task Management API project!

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

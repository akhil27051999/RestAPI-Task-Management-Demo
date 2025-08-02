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

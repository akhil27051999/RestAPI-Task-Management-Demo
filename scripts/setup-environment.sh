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

#!/bin/bash

# Frontend Build Script for Task Management System

set -e

REGISTRY=${REGISTRY:-"your-registry"}
VERSION=${VERSION:-"latest"}
BUILD_ENV=${BUILD_ENV:-"production"}

echo "🔨 Building Frontend Application..."
echo "📦 Registry: $REGISTRY"
echo "🏷️ Version: $VERSION"
echo "🌍 Environment: $BUILD_ENV"

# Navigate to frontend directory
cd 3-frontend

# Validate frontend files
validate_files() {
    echo "📋 Validating frontend files..."
    
    required_files=("src/index.html" "src/css/style.css" "src/js/script.js" "Dockerfile" "nginx.conf")
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            echo "❌ Missing required file: $file"
            exit 1
        fi
    done
    
    echo "✅ All required files present"
}

# Build Docker image
build_image() {
    echo "🐳 Building Docker image..."
    
    # Build with build args for environment
    docker build \
        --build-arg BUILD_ENV=$BUILD_ENV \
        --build-arg VERSION=$VERSION \
        -t $REGISTRY/task-management-frontend:$VERSION \
        -t $REGISTRY/task-management-frontend:latest \
        .
    
    echo "✅ Docker image built successfully"
}

# Test image locally
test_image() {
    echo "🧪 Testing Docker image..."
    
    # Run container for testing
    CONTAINER_ID=$(docker run -d -p 8081:80 $REGISTRY/task-management-frontend:$VERSION)
    
    # Wait for container to start
    sleep 5
    
    # Test if frontend is accessible
    if curl -f http://localhost:8081 > /dev/null 2>&1; then
        echo "✅ Frontend container test passed"
    else
        echo "❌ Frontend container test failed"
        docker logs $CONTAINER_ID
        docker stop $CONTAINER_ID
        exit 1
    fi
    
    # Cleanup test container
    docker stop $CONTAINER_ID
    docker rm $CONTAINER_ID
}

# Push to registry
push_image() {
    echo "📤 Pushing image to registry..."
    
    if [ "$REGISTRY" != "your-registry" ]; then
        docker push $REGISTRY/task-management-frontend:$VERSION
        docker push $REGISTRY/task-management-frontend:latest
        echo "✅ Image pushed to registry"
    else
        echo "⚠️ Skipping push - update REGISTRY variable"
    fi
}

# Generate deployment manifest
generate_manifest() {
    echo "📄 Generating deployment manifest..."
    
    cat > frontend-deployment-$VERSION.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: task-frontend
  labels:
    app: task-frontend
    version: $VERSION
spec:
  replicas: 2
  selector:
    matchLabels:
      app: task-frontend
  template:
    metadata:
      labels:
        app: task-frontend
        version: $VERSION
    spec:
      containers:
      - name: frontend
        image: $REGISTRY/task-management-frontend:$VERSION
        ports:
        - containerPort: 80
        env:
        - name: BUILD_ENV
          value: "$BUILD_ENV"
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
EOF
    
    echo "✅ Deployment manifest generated: frontend-deployment-$VERSION.yaml"
}

# Show build info
show_info() {
    echo ""
    echo "📊 Build Information:"
    echo "Image: $REGISTRY/task-management-frontend:$VERSION"
    echo "Size: $(docker images $REGISTRY/task-management-frontend:$VERSION --format "table {{.Size}}" | tail -n 1)"
    echo "Created: $(docker images $REGISTRY/task-management-frontend:$VERSION --format "table {{.CreatedAt}}" | tail -n 1)"
    echo ""
    echo "🚀 Next Steps:"
    echo "1. Deploy locally: docker run -p 3001:80 $REGISTRY/task-management-frontend:$VERSION"
    echo "2. Deploy to K8s: kubectl apply -f frontend-deployment-$VERSION.yaml"
    echo "3. Update ingress to point to new version"
}

# Cleanup function
cleanup() {
    echo "🧹 Cleaning up..."
    
    # Remove dangling images
    docker image prune -f
    
    # Remove old versions (keep last 3)
    docker images $REGISTRY/task-management-frontend --format "table {{.Tag}}" | \
        grep -v "latest" | grep -v "TAG" | sort -V | head -n -3 | \
        xargs -I {} docker rmi $REGISTRY/task-management-frontend:{} 2>/dev/null || true
    
    echo "✅ Cleanup complete"
}

# Main execution
main() {
    case "${1:-build}" in
        "build")
            validate_files
            build_image
            test_image
            generate_manifest
            show_info
            ;;
        "push")
            validate_files
            build_image
            test_image
            push_image
            generate_manifest
            show_info
            ;;
        "test")
            test_image
            ;;
        "clean")
            cleanup
            ;;
        *)
            echo "Usage: $0 [build|push|test|clean]"
            echo ""
            echo "Environment Variables:"
            echo "  REGISTRY - Docker registry (default: your-registry)"
            echo "  VERSION  - Image version (default: latest)"
            echo "  BUILD_ENV - Build environment (default: production)"
            echo ""
            echo "Examples:"
            echo "  $0 build"
            echo "  REGISTRY=myregistry.com VERSION=v1.2.3 $0 push"
            exit 1
            ;;
    esac
}

main "$@"

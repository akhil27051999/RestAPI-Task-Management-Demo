#!/bin/bash

set -e

PROJECT_NAME="task-management-api"
VERSION="1.0.0"

echo "🚀 Building $PROJECT_NAME v$VERSION..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
mvn clean

# Compile and package
echo "📦 Building application..."
mvn compile package -DskipTests

# Run tests
echo "🧪 Running tests..."
mvn test

# Generate test reports
echo "📊 Generating test reports..."
mvn jacoco:report

# Build Docker image
echo "🐳 Building Docker image..."
docker build -t $PROJECT_NAME:$VERSION .
docker build -t $PROJECT_NAME:latest .

# Verify JAR file
if [ -f "target/$PROJECT_NAME-$VERSION.jar" ]; then
    echo "✅ JAR file created successfully: target/$PROJECT_NAME-$VERSION.jar"
    echo "📏 JAR size: $(du -h target/$PROJECT_NAME-$VERSION.jar | cut -f1)"
else
    echo "❌ JAR file not found!"
    exit 1
fi

# Verify Docker image
if docker images | grep -q $PROJECT_NAME; then
    echo "✅ Docker image created successfully"
    echo "📏 Image size: $(docker images $PROJECT_NAME:latest --format "table {{.Size}}" | tail -n 1)"
else
    echo "❌ Docker image not found!"
    exit 1
fi

echo ""
echo "🎉 Build completed successfully!"
echo "📋 Build artifacts:"
echo "  - JAR: target/$PROJECT_NAME-$VERSION.jar"
echo "  - Docker image: $PROJECT_NAME:$VERSION"
echo "  - Docker image: $PROJECT_NAME:latest"
echo "  - Test reports: target/site/jacoco/index.html"
echo "  - Surefire reports: target/surefire-reports/"

# 5-Local Build & Test Files

## scripts/build.sh
```bash
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
```

## scripts/test.sh
```bash
#!/bin/bash

set -e

echo "🧪 Running comprehensive tests for Task Management API..."

# Set test environment
export SPRING_PROFILES_ACTIVE=test

# Start test database
echo "🗄️ Starting test database..."
docker run -d --name test-mysql \
  -e MYSQL_ROOT_PASSWORD=testpass \
  -e MYSQL_DATABASE=taskdb_test \
  -e MYSQL_USER=testuser \
  -e MYSQL_PASSWORD=testpass \
  -p 3307:3306 \
  mysql:8.0

# Wait for database to be ready
echo "⏳ Waiting for database to be ready..."
sleep 30

# Check if database is ready
until docker exec test-mysql mysqladmin ping -h localhost --silent; do
  echo "Waiting for MySQL..."
  sleep 2
done

echo "✅ Database is ready!"

# Run unit tests
echo "🔬 Running unit tests..."
mvn test -Dtest="*Test"

# Run integration tests
echo "🔗 Running integration tests..."
mvn test -Dtest="*IT" -Dspring.datasource.url=jdbc:mysql://localhost:3307/taskdb_test

# Run all tests with coverage
echo "📊 Running all tests with coverage..."
mvn clean test jacoco:report

# Generate test summary
echo ""
echo "📈 Test Results Summary:"
if [ -f "target/surefire-reports/TEST-*.xml" ]; then
    TOTAL_TESTS=$(grep -h "tests=" target/surefire-reports/TEST-*.xml | sed 's/.*tests="\([0-9]*\)".*/\1/' | awk '{sum+=$1} END {print sum}')
    FAILED_TESTS=$(grep -h "failures=" target/surefire-reports/TEST-*.xml | sed 's/.*failures="\([0-9]*\)".*/\1/' | awk '{sum+=$1} END {print sum}')
    ERRORS=$(grep -h "errors=" target/surefire-reports/TEST-*.xml | sed 's/.*errors="\([0-9]*\)".*/\1/' | awk '{sum+=$1} END {print sum}')
    
    echo "  Total Tests: $TOTAL_TESTS"
    echo "  Failed Tests: $FAILED_TESTS"
    echo "  Errors: $ERRORS"
    echo "  Success Rate: $(( (TOTAL_TESTS - FAILED_TESTS - ERRORS) * 100 / TOTAL_TESTS ))%"
fi

# Check code coverage
if [ -f "target/site/jacoco/index.html" ]; then
    echo "📊 Code coverage report generated: target/site/jacoco/index.html"
fi

# Cleanup test database
echo "🧹 Cleaning up test database..."
docker stop test-mysql || true
docker rm test-mysql || true

# Check test results
if [ "$FAILED_TESTS" -gt 0 ] || [ "$ERRORS" -gt 0 ]; then
    echo "❌ Some tests failed!"
    exit 1
else
    echo "✅ All tests passed!"
fi

echo ""
echo "🎉 Testing completed successfully!"
echo "📋 Test artifacts:"
echo "  - Test reports: target/surefire-reports/"
echo "  - Coverage report: target/site/jacoco/index.html"
echo "  - Test logs: target/surefire-reports/*.txt"
```

## scripts/run-local.sh
```bash
#!/bin/bash

set -e

PROJECT_NAME="task-management-api"
DB_CONTAINER="local-mysql"
APP_CONTAINER="local-task-api"

echo "🚀 Starting Task Management API locally..."

# Function to cleanup on exit
cleanup() {
    echo "🧹 Cleaning up containers..."
    docker stop $APP_CONTAINER $DB_CONTAINER 2>/dev/null || true
    docker rm $APP_CONTAINER $DB_CONTAINER 2>/dev/null || true
}

# Set trap to cleanup on script exit
trap cleanup EXIT

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Start MySQL database
echo "🗄️ Starting MySQL database..."
docker run -d --name $DB_CONTAINER \
  -e MYSQL_ROOT_PASSWORD=password123 \
  -e MYSQL_DATABASE=taskdb \
  -e MYSQL_USER=taskuser \
  -e MYSQL_PASSWORD=taskpass \
  -p 3306:3306 \
  --health-cmd="mysqladmin ping -h localhost" \
  --health-interval=10s \
  --health-timeout=5s \
  --health-retries=5 \
  mysql:8.0

# Wait for database to be healthy
echo "⏳ Waiting for database to be ready..."
until [ "$(docker inspect --format='{{.State.Health.Status}}' $DB_CONTAINER)" = "healthy" ]; do
    echo "Waiting for MySQL to be healthy..."
    sleep 5
done

echo "✅ Database is ready!"

# Build application if JAR doesn't exist
if [ ! -f "target/$PROJECT_NAME-1.0.0.jar" ]; then
    echo "📦 Building application..."
    mvn clean package -DskipTests
fi

# Run application
echo "🚀 Starting application..."
docker run -d --name $APP_CONTAINER \
  --link $DB_CONTAINER:mysql \
  -e SPRING_PROFILES_ACTIVE=dev \
  -e SPRING_DATASOURCE_URL=jdbc:mysql://mysql:3306/taskdb \
  -e SPRING_DATASOURCE_USERNAME=taskuser \
  -e SPRING_DATASOURCE_PASSWORD=taskpass \
  -p 8080:8080 \
  $PROJECT_NAME:latest

# Wait for application to start
echo "⏳ Waiting for application to start..."
sleep 30

# Health check
echo "🏥 Performing health check..."
for i in {1..30}; do
    if curl -f -s http://localhost:8080/actuator/health > /dev/null; then
        echo "✅ Application is healthy!"
        break
    else
        echo "Waiting for application to be ready... ($i/30)"
        sleep 5
    fi
    
    if [ $i -eq 30 ]; then
        echo "❌ Application failed to start properly"
        echo "📋 Application logs:"
        docker logs $APP_CONTAINER
        exit 1
    fi
done

# Display application info
echo ""
echo "🎉 Task Management API is running locally!"
echo ""
echo "📋 Application Information:"
echo "  🌐 API Base URL: http://localhost:8080"
echo "  🏥 Health Check: http://localhost:8080/actuator/health"
echo "  📊 Metrics: http://localhost:8080/actuator/prometheus"
echo "  📖 API Endpoints:"
echo "    - GET    /api/tasks           - Get all tasks"
echo "    - POST   /api/tasks           - Create new task"
echo "    - GET    /api/tasks/{id}      - Get task by ID"
echo "    - PUT    /api/tasks/{id}      - Update task"
echo "    - DELETE /api/tasks/{id}      - Delete task"
echo ""
echo "🗄️ Database Information:"
echo "  📍 Host: localhost:3306"
echo "  🗃️ Database: taskdb"
echo "  👤 Username: taskuser"
echo "  🔑 Password: taskpass"
echo ""

# Test API endpoints
echo "🧪 Testing API endpoints..."

# Test health endpoint
echo "Testing health endpoint..."
curl -s http://localhost:8080/actuator/health | jq . || echo "Health check response received"

# Test create task
echo "Testing create task..."
TASK_ID=$(curl -s -X POST http://localhost:8080/api/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Task",
    "description": "This is a test task created by run-local script",
    "priority": "HIGH"
  }' | jq -r '.id' 2>/dev/null || echo "1")

echo "Created task with ID: $TASK_ID"

# Test get all tasks
echo "Testing get all tasks..."
curl -s http://localhost:8080/api/tasks | jq . || echo "Get all tasks response received"

echo ""
echo "✅ API testing completed!"
echo ""
echo "🔧 Useful commands:"
echo "  📋 View application logs: docker logs -f $APP_CONTAINER"
echo "  📋 View database logs: docker logs -f $DB_CONTAINER"
echo "  🗄️ Connect to database: docker exec -it $DB_CONTAINER mysql -u taskuser -p taskdb"
echo "  🛑 Stop application: docker stop $APP_CONTAINER $DB_CONTAINER"
echo ""
echo "Press Ctrl+C to stop the application and cleanup containers"

# Keep script running
while true; do
    sleep 10
    # Check if containers are still running
    if ! docker ps | grep -q $APP_CONTAINER; then
        echo "❌ Application container stopped unexpectedly"
        docker logs $APP_CONTAINER
        break
    fi
done
```

## README.md
```markdown
# Local Build & Test Environment

## Overview
This directory contains scripts for building, testing, and running the Task Management API locally for development and testing purposes.

## Prerequisites
- Java 17+
- Maven 3.6+
- Docker & Docker Compose
- curl (for API testing)
- jq (for JSON parsing, optional)

## Scripts

### 1. build.sh
Builds the application and creates Docker images.

**Features:**
- Cleans previous builds
- Compiles and packages the application
- Runs unit tests
- Generates test coverage reports
- Builds Docker images
- Verifies build artifacts

**Usage:**
```bash
chmod +x scripts/build.sh
./scripts/build.sh
```

**Output:**
- JAR file: `target/task-management-api-1.0.0.jar`
- Docker images: `task-management-api:1.0.0` and `task-management-api:latest`
- Test reports: `target/site/jacoco/index.html`

### 2. test.sh
Runs comprehensive tests with a temporary test database.

**Features:**
- Starts temporary MySQL test database
- Runs unit tests
- Runs integration tests
- Generates code coverage reports
- Provides test summary
- Cleans up test environment

**Usage:**
```bash
chmod +x scripts/test.sh
./scripts/test.sh
```

**Output:**
- Test reports: `target/surefire-reports/`
- Coverage report: `target/site/jacoco/index.html`
- Test summary with success rate

### 3. run-local.sh
Runs the complete application stack locally using Docker.

**Features:**
- Starts MySQL database container
- Builds application if needed
- Runs application container
- Performs health checks
- Tests API endpoints
- Provides connection information

**Usage:**
```bash
chmod +x scripts/run-local.sh
./scripts/run-local.sh
```

**Access Points:**
- API: http://localhost:8080
- Health: http://localhost:8080/actuator/health
- Metrics: http://localhost:8080/actuator/prometheus

## Quick Start

### 1. Build Application
```bash
./scripts/build.sh
```

### 2. Run Tests
```bash
./scripts/test.sh
```

### 3. Start Local Environment
```bash
./scripts/run-local.sh
```

### 4. Test API
```bash
# Health check
curl http://localhost:8080/actuator/health

# Create task
curl -X POST http://localhost:8080/api/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "My First Task",
    "description": "This is a test task",
    "priority": "HIGH"
  }'

# Get all tasks
curl http://localhost:8080/api/tasks

# Get specific task
curl http://localhost:8080/api/tasks/1
```

## Development Workflow

### 1. Code Changes
```bash
# Make your code changes
# Run tests to verify
./scripts/test.sh

# Build new version
./scripts/build.sh
```

### 2. Local Testing
```bash
# Start local environment
./scripts/run-local.sh

# Test your changes
# Use Postman, curl, or browser
```

### 3. Integration Testing
```bash
# Run full test suite
./scripts/test.sh

# Check coverage reports
open target/site/jacoco/index.html
```

## Troubleshooting

### Common Issues

1. **Port already in use**
```bash
# Check what's using port 8080
lsof -i :8080

# Kill process if needed
kill -9 <PID>
```

2. **Docker containers not starting**
```bash
# Check Docker status
docker ps -a

# View container logs
docker logs <container-name>

# Clean up containers
docker stop $(docker ps -aq)
docker rm $(docker ps -aq)
```

3. **Database connection issues**
```bash
# Check MySQL container
docker exec -it local-mysql mysql -u taskuser -p

# Verify database exists
SHOW DATABASES;
USE taskdb;
SHOW TABLES;
```

4. **Build failures**
```bash
# Clean Maven cache
mvn clean

# Update dependencies
mvn dependency:resolve

# Check Java version
java -version
mvn -version
```

### Logs and Debugging

```bash
# Application logs
docker logs -f local-task-api

# Database logs
docker logs -f local-mysql

# Maven debug
mvn -X test

# Spring Boot debug
export SPRING_PROFILES_ACTIVE=dev
export LOGGING_LEVEL_COM_TASKAPI=DEBUG
```

## Environment Variables

### Development
```bash
export SPRING_PROFILES_ACTIVE=dev
export SPRING_DATASOURCE_URL=jdbc:mysql://localhost:3306/taskdb
export SPRING_DATASOURCE_USERNAME=taskuser
export SPRING_DATASOURCE_PASSWORD=taskpass
```

### Testing
```bash
export SPRING_PROFILES_ACTIVE=test
export SPRING_DATASOURCE_URL=jdbc:mysql://localhost:3307/taskdb_test
```

## Performance Testing

### Load Testing with curl
```bash
# Simple load test
for i in {1..100}; do
  curl -s http://localhost:8080/api/tasks > /dev/null &
done
wait
```

### Memory and CPU Monitoring
```bash
# Monitor Docker containers
docker stats

# Monitor Java process
jps -l
jstat -gc <pid>
```

## Cleanup

### Stop Local Environment
```bash
# Stop containers
docker stop local-task-api local-mysql

# Remove containers
docker rm local-task-api local-mysql

# Remove images (optional)
docker rmi task-management-api:latest
```

### Clean Build Artifacts
```bash
# Clean Maven build
mvn clean

# Remove Docker images
docker system prune -f
```

This local development environment provides everything needed for efficient development, testing, and debugging of the Task Management API.
```

## Usage Instructions

### Make Scripts Executable
```bash
chmod +x 5-local-build-test/scripts/*.sh
```

### Run Scripts
```bash
# Build application
./5-local-build-test/scripts/build.sh

# Run tests
./5-local-build-test/scripts/test.sh

# Start local environment
./5-local-build-test/scripts/run-local.sh
```

This provides a complete local development environment with build automation, comprehensive testing, and local runtime setup.

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

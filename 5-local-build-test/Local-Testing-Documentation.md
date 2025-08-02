# Local Testing with Docker Compose - Documentation

## Overview
This document provides comprehensive guidance for local testing of the Task Management API using Docker Compose, including troubleshooting steps encountered during the build process.

## Prerequisites
- Docker 20.10+
- Docker Compose 2.0+
- 4GB+ available RAM
- Ports 3000, 8080, 9090 available

## Project Structure
```
4-containerization/
├── Dockerfile                    # Application container image
├── docker-compose.yml           # Multi-service orchestration
├── .dockerignore                # Build context optimization
└── README.md                    # This documentation
```

## Quick Start Guide

### 1. Navigate to Containerization Directory
```bash
cd RestAPI-Task-Management-Demo/4-containerization
```

### 2. Start All Services
```bash
# Start all services in detached mode
sudo docker compose up -d

# Check service status
sudo docker compose ps
```

### 3. Wait for Services to Initialize
```bash
# Wait for all services to be ready (approximately 90 seconds)
sleep 90

# Verify application health
curl http://localhost:8080/actuator/health
```

### 4. Test API Functionality
```bash
# Test health endpoint
curl http://localhost:8080/actuator/health

# Get all tasks (initially empty)
curl http://localhost:8080/api/tasks

# Create a new task
curl -X POST http://localhost:8080/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"title":"Test Task","description":"Testing local deployment","status":"PENDING"}'

# Retrieve all tasks (should show created task)
curl http://localhost:8080/api/tasks

# Create another task
curl -X POST http://localhost:8080/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"title":"Second Task","description":"Another test","status":"IN_PROGRESS"}'

# Get specific task by ID
curl http://localhost:8080/api/tasks/1

# Update a task
curl -X PUT http://localhost:8080/api/tasks/1 \
  -H "Content-Type: application/json" \
  -d '{"title":"Updated Task","description":"Task updated","status":"COMPLETED"}'

# Delete a task
curl -X DELETE http://localhost:8080/api/tasks/2
```

## Service Access Points

### Application Services
| Service | URL | Credentials | Purpose |
|---------|-----|-------------|---------|
| Task API | http://localhost:8080 | None | REST API endpoints |
| Health Check | http://localhost:8080/actuator/health | None | Application health |
| Metrics | http://localhost:8080/actuator/prometheus | None | Prometheus metrics |

### Monitoring Services
| Service | URL | Credentials | Purpose |
|---------|-----|-------------|---------|
| Grafana | http://localhost:3000 | admin/admin123 | Monitoring dashboards |
| Prometheus | http://localhost:9090 | None | Metrics collection |

### Database Access
```bash
# Connect to MySQL database
sudo docker exec -it task-mysql mysql -u taskuser -p taskdb
# Password: taskpass

# Inside MySQL console:
SHOW TABLES;
SELECT * FROM tasks;
EXIT;
```

## Docker Compose Configuration

### Services Overview
```yaml
services:
  mysql:        # Database service
  app:          # Spring Boot application
  prometheus:   # Metrics collection
  grafana:      # Monitoring dashboards
```

### Key Features
- **Health Checks**: All services have health check configurations
- **Dependency Management**: App waits for MySQL to be healthy
- **Persistent Storage**: MySQL data and Grafana configurations persist
- **Network Isolation**: Custom bridge network for service communication
- **Environment Variables**: Configurable database credentials

## Troubleshooting Guide

### Issues Encountered During Build

#### 1. Docker Image Not Found Error
**Problem:**
```
failed to solve: openjdk:17-jre-slim: not found
```

**Root Cause:** The `openjdk:17-jre-slim` Docker image was deprecated and removed from Docker Hub.

**Solution Applied:**
```dockerfile
# Changed from:
FROM openjdk:17-jre-slim

# To:
FROM eclipse-temurin:17-jre-alpine
```

**Fix Commands:**
```bash
# Update Dockerfile with correct base images
cat > Dockerfile << 'EOF'
FROM eclipse-temurin:17-jdk-alpine as builder
# ... rest of Dockerfile
FROM eclipse-temurin:17-jre-alpine
# ... rest of Dockerfile
EOF
```

#### 2. Source Files Not Found Error
**Problem:**
```
failed to calculate checksum: "/.mvn": not found
failed to calculate checksum: "/src": not found
failed to calculate checksum: "/pom.xml": not found
```

**Root Cause:** Dockerfile was looking for source files in the wrong directory context.

**Solution Applied:**
1. **Option 1**: Copy source files to build context
```bash
cp -r ../2-source-code/* ./
```

2. **Option 2**: Build from source directory (Used)
```bash
cd ../2-source-code
sudo docker build -t task-management-api .
```

3. **Option 3**: Update docker-compose.yml to use pre-built image
```yaml
services:
  app:
    image: task-management-api:latest  # Instead of build context
```

#### 3. Maven Build Error - Missing Dependency Version
**Problem:**
```
'dependencies.dependency.version' for mysql:mysql-connector-java:jar is missing
```

**Root Cause:** The `pom.xml` file had MySQL dependency without explicit version.

**Solution Applied:**
```xml
<!-- Fixed dependency with explicit version -->
<dependency>
    <groupId>mysql</groupId>
    <artifactId>mysql-connector-java</artifactId>
    <version>8.0.33</version>
    <scope>runtime</scope>
</dependency>
```

**Fix Commands:**
```bash
# Updated pom.xml with complete dependency configuration
cat > pom.xml << 'EOF'
# ... complete pom.xml with proper MySQL dependency
EOF
```

#### 4. Maven Wrapper Missing
**Problem:** Dockerfile expected Maven wrapper files (`.mvn/`, `mvnw`) that weren't present.

**Solution Applied:**
```dockerfile
# Changed from Maven wrapper approach:
COPY .mvn/ .mvn/
COPY mvnw pom.xml ./
RUN ./mvnw dependency:go-offline -B

# To direct Maven installation:
COPY pom.xml ./
COPY src ./src
RUN apk add --no-cache maven
RUN mvn clean package -DskipTests
```

## Monitoring and Observability

### Grafana Dashboard Setup
1. **Access Grafana**: http://localhost:3000
2. **Login**: admin/admin123
3. **Add Prometheus Data Source**:
   - URL: http://prometheus:9090
   - Access: Server (default)
4. **Import Dashboards**:
   - Spring Boot Dashboard (ID: 12900)
   - JVM Dashboard (ID: 4701)

### Prometheus Metrics
- **Application Metrics**: http://localhost:8080/actuator/prometheus
- **Prometheus UI**: http://localhost:9090
- **Key Metrics**:
  - `http_server_requests_seconds_count` - Request count
  - `http_server_requests_seconds_sum` - Response time
  - `jvm_memory_used_bytes` - Memory usage

## Maintenance Commands

### Service Management
```bash
# Start services
sudo docker compose up -d

# Stop services
sudo docker compose down

# Restart specific service
sudo docker compose restart app

# View logs
sudo docker compose logs -f app
sudo docker compose logs mysql

# Check service status
sudo docker compose ps
```

### Data Management
```bash
# Backup database
sudo docker exec task-mysql mysqldump -u taskuser -p taskdb > backup.sql

# Restore database
sudo docker exec -i task-mysql mysql -u taskuser -p taskdb < backup.sql

# Clear all data (destructive)
sudo docker compose down -v
```

### Image Management
```bash
# Rebuild application image
sudo docker build -t task-management-api .

# Remove unused images
sudo docker image prune

# View image sizes
sudo docker images
```

## Performance Testing

### Load Testing with curl
```bash
# Simple load test
for i in {1..10}; do
  curl -X POST http://localhost:8080/api/tasks \
    -H "Content-Type: application/json" \
    -d "{\"title\":\"Load Test $i\",\"description\":\"Performance testing\"}" &
done
wait

# Check created tasks
curl http://localhost:8080/api/tasks
```

### Resource Monitoring
```bash
# Monitor container resources
sudo docker stats

# Check container processes
sudo docker exec task-api ps aux

# View container logs in real-time
sudo docker compose logs -f
```

## Security Considerations

### Container Security
- **Non-root User**: Application runs as `appuser` (UID 1000)
- **Minimal Base Image**: Uses Alpine Linux for smaller attack surface
- **Health Checks**: Built-in container health monitoring
- **Network Isolation**: Services communicate via custom bridge network

### Data Security
- **Environment Variables**: Database credentials via environment variables
- **Volume Permissions**: Proper file ownership and permissions
- **Network Policies**: Isolated container networking

## Cleanup Procedures

### Complete Cleanup
```bash
# Stop and remove all containers, networks, and volumes
sudo docker compose down -v

# Remove application image
sudo docker rmi task-management-api

# Clean up unused Docker resources
sudo docker system prune -a
```

### Selective Cleanup
```bash
# Stop services only
sudo docker compose stop

# Remove containers but keep volumes
sudo docker compose down

# Remove specific service
sudo docker compose rm app
```

## Success Verification Checklist

- [ ] All containers running: `sudo docker compose ps`
- [ ] Health check passing: `curl http://localhost:8080/actuator/health`
- [ ] API responding: `curl http://localhost:8080/api/tasks`
- [ ] Database connected: MySQL status in health check
- [ ] Grafana accessible: http://localhost:3000
- [ ] Prometheus accessible: http://localhost:9090
- [ ] CRUD operations working: Create, read, update, delete tasks
- [ ] Monitoring data flowing: Metrics visible in Grafana

## Troubleshooting Quick Reference

| Issue | Command | Expected Result |
|-------|---------|----------------|
| Container not starting | `sudo docker compose logs <service>` | Error details |
| API not responding | `curl http://localhost:8080/actuator/health` | `{"status":"UP"}` |
| Database connection | `sudo docker exec -it task-mysql mysql -u taskuser -p` | MySQL prompt |
| Port conflicts | `sudo netstat -tulpn \| grep :8080` | No output if free |
| Resource issues | `sudo docker stats` | Container resource usage |

This documentation provides a complete guide for local testing and troubleshooting of the Task Management API using Docker Compose.

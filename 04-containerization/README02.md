# 4-Containerization Files

## Dockerfile
```dockerfile
# Multi-stage build for production optimization
FROM openjdk:17-jdk-slim as builder

WORKDIR /app

# Copy Maven wrapper and pom.xml for dependency caching
COPY .mvn/ .mvn/
COPY mvnw pom.xml ./

# Download dependencies (cached layer)
RUN ./mvnw dependency:go-offline -B

# Copy source code
COPY src ./src

# Build application
RUN ./mvnw clean package -DskipTests

# Production stage
FROM openjdk:17-jre-slim

# Create non-root user for security
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Install curl for health checks and clean up
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy JAR from builder stage
COPY --from=builder /app/target/task-management-api-*.jar app.jar

# Change ownership to non-root user
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1

# Expose port
EXPOSE 8080

# JVM optimization for containers
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -XX:+UseG1GC"

# Run application
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
```

## docker-compose.yml
```yaml
version: '3.8'

services:
  mysql:
    image: mysql:8.0
    container_name: task-mysql
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: taskdb
      MYSQL_USER: taskuser
      MYSQL_PASSWORD: taskpass
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql
      - ./init-scripts:/docker-entrypoint-initdb.d
    networks:
      - task-network
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      timeout: 20s
      retries: 10
      interval: 30s
      start_period: 60s
    restart: unless-stopped

  app:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: task-api
    environment:
      SPRING_PROFILES_ACTIVE: docker
      SPRING_DATASOURCE_URL: jdbc:mysql://mysql:3306/taskdb
      SPRING_DATASOURCE_USERNAME: taskuser
      SPRING_DATASOURCE_PASSWORD: taskpass
      DB_HOST: mysql
      DB_PORT: 3306
      DB_NAME: taskdb
      DB_USERNAME: taskuser
      DB_PASSWORD: taskpass
    ports:
      - "8080:8080"
    depends_on:
      mysql:
        condition: service_healthy
    networks:
      - task-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/actuator/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 90s
    restart: unless-stopped
    volumes:
      - app_logs:/app/logs

  prometheus:
    image: prom/prometheus:latest
    container_name: task-prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus_data:/prometheus
    networks:
      - task-network
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=200h'
      - '--web.enable-lifecycle'
    restart: unless-stopped

  grafana:
    image: grafana/grafana:latest
    container_name: task-grafana
    ports:
      - "3000:3000"
    environment:
      GF_SECURITY_ADMIN_USER: admin
      GF_SECURITY_ADMIN_PASSWORD: admin123
      GF_USERS_ALLOW_SIGN_UP: false
    volumes:
      - grafana_data:/var/lib/grafana
      - ./monitoring/grafana/dashboards:/etc/grafana/provisioning/dashboards:ro
      - ./monitoring/grafana/datasources:/etc/grafana/provisioning/datasources:ro
    networks:
      - task-network
    restart: unless-stopped
    depends_on:
      - prometheus

volumes:
  mysql_data:
    driver: local
  prometheus_data:
    driver: local
  grafana_data:
    driver: local
  app_logs:
    driver: local

networks:
  task-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

## .dockerignore
```
# Maven
target/
!target/task-management-api-*.jar
pom.xml.tag
pom.xml.releaseBackup
pom.xml.versionsBackup
pom.xml.next
release.properties
dependency-reduced-pom.xml
buildNumber.properties
.mvn/timing.properties
.mvn/wrapper/maven-wrapper.jar

# IDE
.idea/
*.iws
*.iml
*.ipr
.vscode/
.classpath
.project
.settings/
*.swp
*.swo

# OS
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Git
.git
.gitignore
.gitattributes

# Documentation
README.md
*.md
docs/

# Docker
Dockerfile*
docker-compose*
.dockerignore

# Logs
*.log
logs/

# Runtime
*.pid
*.seed
*.pid.lock

# Environment
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# Test
src/test/
test-results/
coverage/

# Temporary files
*.tmp
*.temp
.cache/

# Node modules (if any)
node_modules/
npm-debug.log*

# Python (if any)
__pycache__/
*.py[cod]
*$py.class

# Backup files
*.bak
*.backup
*~
```

## README.md
```markdown
# Containerization Guide

## Overview
This directory contains Docker configuration files for containerizing the Task Management API with a complete development and production setup.

## Files Structure
```
4-containerization/
├── Dockerfile              # Multi-stage production Docker image
├── docker-compose.yml      # Complete stack with monitoring
├── .dockerignore           # Docker build context optimization
└── README.md              # This documentation
```

## Docker Image Features

### Multi-Stage Build
- **Builder stage**: Uses JDK for compilation
- **Runtime stage**: Uses JRE for smaller image size
- **Dependency caching**: Optimized layer caching for faster builds

### Security
- **Non-root user**: Runs as `appuser` for security
- **Minimal base image**: Uses `openjdk:17-jre-slim`
- **Health checks**: Built-in container health monitoring

### Performance
- **JVM optimization**: Container-aware JVM settings
- **G1 garbage collector**: Optimized for low-latency applications
- **Memory management**: 75% RAM allocation limit

## Docker Compose Stack

### Services
1. **MySQL Database**
   - Persistent data storage
   - Health checks
   - Initialization scripts support

2. **Task API Application**
   - Spring Boot application
   - Depends on MySQL health
   - Automatic restart policy

3. **Prometheus** (Monitoring)
   - Metrics collection
   - Configurable retention
   - Web interface on port 9090

4. **Grafana** (Visualization)
   - Dashboard visualization
   - Pre-configured datasources
   - Web interface on port 3000

### Networking
- **Custom bridge network**: Isolated communication
- **Service discovery**: Services communicate by name
- **Port mapping**: External access to required services

## Quick Start

### Prerequisites
- Docker 20.10+
- Docker Compose 2.0+
- 4GB+ available RAM

### 1. Build and Start
```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Check status
docker-compose ps
```

### 2. Access Services
- **API**: http://localhost:8080
- **Health Check**: http://localhost:8080/actuator/health
- **Metrics**: http://localhost:8080/actuator/prometheus
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3000 (admin/admin123)

### 3. Test API
```bash
# Health check
curl http://localhost:8080/actuator/health

# Create task
curl -X POST http://localhost:8080/api/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Docker Test Task",
    "description": "Testing containerized API",
    "priority": "HIGH"
  }'

# Get all tasks
curl http://localhost:8080/api/tasks
```

## Development Workflow

### 1. Code Changes
```bash
# Rebuild application image
docker-compose build app

# Restart application
docker-compose restart app
```

### 2. Database Management
```bash
# Connect to MySQL
docker-compose exec mysql mysql -u taskuser -p taskdb

# View database logs
docker-compose logs mysql

# Reset database
docker-compose down -v
docker-compose up -d
```

### 3. Monitoring
```bash
# View application logs
docker-compose logs -f app

# Check container stats
docker stats

# View Prometheus targets
open http://localhost:9090/targets
```

## Production Deployment

### 1. Environment Variables
Create `.env` file:
```env
# Database
MYSQL_ROOT_PASSWORD=secure_root_password
MYSQL_PASSWORD=secure_user_password

# Application
SPRING_PROFILES_ACTIVE=prod
JAVA_OPTS=-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0

# Monitoring
GF_SECURITY_ADMIN_PASSWORD=secure_grafana_password
```

### 2. Production Compose Override
Create `docker-compose.prod.yml`:
```yaml
version: '3.8'
services:
  app:
    image: your-registry/task-management-api:latest
    environment:
      SPRING_PROFILES_ACTIVE: prod
    deploy:
      replicas: 3
      resources:
        limits:
          memory: 1G
          cpus: '0.5'
  
  mysql:
    volumes:
      - /opt/mysql-data:/var/lib/mysql
```

### 3. Deploy to Production
```bash
# Use production configuration
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

## Monitoring Setup

### Prometheus Configuration
Create `monitoring/prometheus.yml`:
```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'task-management-api'
    static_configs:
      - targets: ['app:8080']
    metrics_path: '/actuator/prometheus'
    scrape_interval: 30s
```

### Grafana Dashboards
- Import dashboard ID: 4701 (JVM Micrometer)
- Import dashboard ID: 12900 (Spring Boot)
- Custom application metrics dashboard

## Troubleshooting

### Common Issues

1. **Port conflicts**
```bash
# Check port usage
netstat -tulpn | grep :8080

# Use different ports
docker-compose up -d --scale app=0
docker-compose run -p 8081:8080 app
```

2. **Database connection issues**
```bash
# Check MySQL logs
docker-compose logs mysql

# Verify network connectivity
docker-compose exec app ping mysql

# Check database status
docker-compose exec mysql mysqladmin ping
```

3. **Application startup failures**
```bash
# Check application logs
docker-compose logs app

# Debug with interactive shell
docker-compose run --rm app bash

# Check health status
docker-compose exec app curl localhost:8080/actuator/health
```

4. **Memory issues**
```bash
# Check container memory usage
docker stats

# Adjust JVM settings
export JAVA_OPTS="-XX:MaxRAMPercentage=50.0"
docker-compose up -d
```

### Debugging Commands

```bash
# Enter container shell
docker-compose exec app bash

# View container processes
docker-compose exec app ps aux

# Check disk usage
docker-compose exec app df -h

# View environment variables
docker-compose exec app env

# Check Java process
docker-compose exec app jps -l
```

## Performance Optimization

### 1. Image Size Optimization
- Multi-stage builds reduce image size by ~60%
- .dockerignore excludes unnecessary files
- Minimal base images (JRE vs JDK)

### 2. Build Performance
```bash
# Use BuildKit for faster builds
export DOCKER_BUILDKIT=1
docker build .

# Parallel builds
docker-compose build --parallel
```

### 3. Runtime Performance
- Container-aware JVM settings
- Optimized garbage collection
- Health check intervals
- Resource limits

## Security Best Practices

### 1. Container Security
- Non-root user execution
- Read-only root filesystem (where possible)
- Minimal attack surface
- Regular base image updates

### 2. Network Security
- Custom bridge networks
- No unnecessary port exposure
- Service-to-service communication

### 3. Secret Management
```bash
# Use Docker secrets in production
echo "secure_password" | docker secret create mysql_password -

# Reference in compose file
secrets:
  - mysql_password
```

## Cleanup

### Stop Services
```bash
# Stop all services
docker-compose down

# Remove volumes (data loss!)
docker-compose down -v

# Remove images
docker-compose down --rmi all
```

### System Cleanup
```bash
# Remove unused containers
docker container prune

# Remove unused images
docker image prune

# Remove unused volumes
docker volume prune

# Complete cleanup
docker system prune -a
```

This containerization setup provides a complete, production-ready environment with monitoring, security, and performance optimizations.
```

## Usage Instructions

### Quick Start
```bash
# Navigate to containerization directory
cd 4-containerization/

# Start all services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f app
```

### Access Points
- **API**: http://localhost:8080/api/tasks
- **Health**: http://localhost:8080/actuator/health
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3000 (admin/admin123)

### Cleanup
```bash
# Stop services
docker-compose down

# Remove volumes
docker-compose down -v
```

This containerization setup provides a complete development and production environment with monitoring, security, and performance optimizations.

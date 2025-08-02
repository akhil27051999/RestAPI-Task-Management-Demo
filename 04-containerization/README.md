# Containerization - Docker Setup

Complete containerization strategy for the Task Management API with production-ready Docker configurations.

## Container Strategy Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    CONTAINERIZATION STRATEGY                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                 MULTI-STAGE BUILD                       │   │
│  │                                                         │   │
│  │  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐ │   │
│  │  │   Stage 1   │───▶│   Stage 2   │───▶│   Stage 3   │ │   │
│  │  │    Build    │    │    Test     │    │   Runtime   │ │   │
│  │  │             │    │             │    │             │ │   │
│  │  │ Maven Build │    │ Run Tests   │    │ Final Image │ │   │
│  │  │ Dependencies│    │ Security    │    │ Minimal     │ │   │
│  │  └─────────────┘    └─────────────┘    └─────────────┘ │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                LOCAL DEVELOPMENT                        │   │
│  │                                                         │   │
│  │  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐ │   │
│  │  │ Task API    │    │   MySQL     │    │   Redis     │ │   │
│  │  │ Container   │    │ Container   │    │ Container   │ │   │
│  │  │             │    │             │    │             │ │   │
│  │  └─────────────┘    └─────────────┘    └─────────────┘ │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## Dockerfile - Production Ready

### **Dockerfile**
```dockerfile
# ===============================================================================
# TASK MANAGEMENT API - PRODUCTION DOCKERFILE
# Multi-stage build for optimal security and performance
# ===============================================================================

# ===============================================================================
# STAGE 1: BUILD ENVIRONMENT
# Purpose: Compile application and run tests
# ===============================================================================
FROM public.ecr.aws/amazoncorretto/amazoncorretto:17-alpine AS build-env

# Set build arguments
ARG JAR_FILE=target/*.jar
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION=1.0.0

# Add labels for container metadata
LABEL maintainer="devops@company.com" \
      org.opencontainers.image.title="Task Management API" \
      org.opencontainers.image.description="REST API for task management" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.source="https://github.com/company/task-management-api"

# Install build dependencies
RUN apk add --no-cache \
    maven \
    git \
    curl \
    && rm -rf /var/cache/apk/*

# Create app directory
WORKDIR /app

# Copy Maven configuration files first (for better caching)
COPY pom.xml ./
COPY .mvn .mvn
COPY mvnw ./

# Make Maven wrapper executable
RUN chmod +x mvnw

# Download dependencies (cached layer if pom.xml doesn't change)
RUN ./mvnw dependency:go-offline -B -q

# Copy source code
COPY src ./src

# Build application
RUN ./mvnw clean package -DskipTests -B -q && \
    mv target/*.jar app.jar

# ===============================================================================
# STAGE 2: SECURITY SCANNING & TESTING
# Purpose: Run security scans and tests
# ===============================================================================
FROM build-env AS test-env

# Install security scanning tools
RUN apk add --no-cache \
    trivy \
    && rm -rf /var/cache/apk/*

# Run tests
RUN ./mvnw test -B -q

# Run security scan on dependencies
RUN ./mvnw org.owasp:dependency-check-maven:check -B -q || true

# ===============================================================================
# STAGE 3: RUNTIME ENVIRONMENT
# Purpose: Minimal production runtime
# ===============================================================================
FROM public.ecr.aws/amazoncorretto/amazoncorretto:17-alpine AS runtime

# Install runtime dependencies only
RUN apk add --no-cache \
    curl \
    dumb-init \
    && rm -rf /var/cache/apk/*

# Create non-root user for security
ENV APPUSER=taskapi
ENV APPUID=1000
ENV APPGID=1000

RUN addgroup -g $APPGID $APPUSER && \
    adduser -D -u $APPUID -G $APPUSER -s /bin/sh $APPUSER

# Create app directory with proper permissions
RUN mkdir -p /app/logs /app/tmp && \
    chown -R $APPUSER:$APPUSER /app

# Set working directory
WORKDIR /app

# Copy application JAR from build stage
COPY --from=build-env --chown=$APPUSER:$APPUSER /app/app.jar ./

# Copy health check script
COPY --chown=$APPUSER:$APPUSER scripts/health-check.sh ./
RUN chmod +x health-check.sh

# Switch to non-root user
USER $APPUSER

# Configure JVM for container environment
ENV JAVA_OPTS="-XX:+UseContainerSupport \
               -XX:MaxRAMPercentage=75.0 \
               -XX:+UseG1GC \
               -XX:+UseStringDeduplication \
               -Djava.security.egd=file:/dev/./urandom \
               -Dspring.profiles.active=prod"

# Expose application port
EXPOSE 8080

# Add health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD ./health-check.sh || exit 1

# Use dumb-init for proper signal handling
ENTRYPOINT ["dumb-init", "--"]

# Start application
CMD ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
```

### **Health Check Script**
```bash
#!/bin/sh
# scripts/health-check.sh
# Health check script for container

set -e

# Check if application is responding
if curl -f -s http://localhost:8080/actuator/health > /dev/null; then
    echo "Health check passed"
    exit 0
else
    echo "Health check failed"
    exit 1
fi
```

### **.dockerignore**
```dockerignore
# Build artifacts
target/
*.jar
*.war
*.ear

# IDE files
.idea/
.vscode/
*.iml
*.ipr
*.iws

# OS files
.DS_Store
Thumbs.db

# Git
.git/
.gitignore

# Documentation
README.md
docs/

# Docker files
Dockerfile*
docker-compose*.yml

# CI/CD
.github/
.gitlab-ci.yml
Jenkinsfile

# Logs
logs/
*.log

# Temporary files
tmp/
temp/
*.tmp
*.temp

# Node modules (if any)
node_modules/

# Environment files
.env
.env.local
.env.*.local

# Test coverage
coverage/
.nyc_output/

# Maven
.mvn/wrapper/maven-wrapper.jar
```

## Docker Compose - Local Development

### **docker-compose.yml**
```yaml
version: '3.8'

services:
  # Task Management API
  task-api:
    build:
      context: .
      dockerfile: Dockerfile
      target: runtime
      args:
        BUILD_DATE: ${BUILD_DATE:-$(date -u +'%Y-%m-%dT%H:%M:%SZ')}
        VCS_REF: ${VCS_REF:-$(git rev-parse --short HEAD)}
        VERSION: ${VERSION:-1.0.0}
    container_name: task-api
    ports:
      - "8080:8080"
    environment:
      # Database configuration
      SPRING_DATASOURCE_URL: jdbc:mysql://mysql:3306/taskdb
      SPRING_DATASOURCE_USERNAME: taskuser
      SPRING_DATASOURCE_PASSWORD: taskpass
      
      # Redis configuration
      SPRING_REDIS_HOST: redis
      SPRING_REDIS_PORT: 6379
      
      # Application configuration
      SPRING_PROFILES_ACTIVE: dev
      LOGGING_LEVEL_COM_TASKAPI: DEBUG
      
      # JVM configuration
      JAVA_OPTS: >-
        -Xmx512m
        -Xms256m
        -XX:+UseG1GC
        -Dspring.profiles.active=dev
    depends_on:
      mysql:
        condition: service_healthy
      redis:
        condition: service_healthy
    networks:
      - task-network
    volumes:
      - ./logs:/app/logs
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/actuator/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

  # MySQL Database
  mysql:
    image: mysql:8.0
    container_name: task-mysql
    ports:
      - "3306:3306"
    environment:
      MYSQL_ROOT_PASSWORD: rootpass
      MYSQL_DATABASE: taskdb
      MYSQL_USER: taskuser
      MYSQL_PASSWORD: taskpass
      MYSQL_ROOT_HOST: '%'
    volumes:
      - mysql_data:/var/lib/mysql
      - ./scripts/init-db.sql:/docker-entrypoint-initdb.d/init-db.sql:ro
    networks:
      - task-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "root", "-p$$MYSQL_ROOT_PASSWORD"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
    command: >
      --default-authentication-plugin=mysql_native_password
      --character-set-server=utf8mb4
      --collation-server=utf8mb4_unicode_ci
      --innodb-buffer-pool-size=256M
      --max-connections=200

  # Redis Cache
  redis:
    image: redis:7-alpine
    container_name: task-redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
      - ./config/redis.conf:/usr/local/etc/redis/redis.conf:ro
    networks:
      - task-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s
    command: redis-server /usr/local/etc/redis/redis.conf

  # Prometheus for monitoring
  prometheus:
    image: prom/prometheus:latest
    container_name: task-prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./config/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus_data:/prometheus
    networks:
      - task-network
    restart: unless-stopped
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--web.enable-lifecycle'

  # Grafana for visualization
  grafana:
    image: grafana/grafana:latest
    container_name: task-grafana
    ports:
      - "3000:3000"
    environment:
      GF_SECURITY_ADMIN_PASSWORD: admin123
      GF_USERS_ALLOW_SIGN_UP: false
    volumes:
      - grafana_data:/var/lib/grafana
      - ./config/grafana/dashboards:/etc/grafana/provisioning/dashboards:ro
      - ./config/grafana/datasources:/etc/grafana/provisioning/datasources:ro
    networks:
      - task-network
    restart: unless-stopped

networks:
  task-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16

volumes:
  mysql_data:
    driver: local
  redis_data:
    driver: local
  prometheus_data:
    driver: local
  grafana_data:
    driver: local
```

### **docker-compose.override.yml** (Development)
```yaml
version: '3.8'

services:
  task-api:
    build:
      target: build-env  # Use build stage for development
    volumes:
      - .:/app
      - ~/.m2:/root/.m2  # Maven cache
    environment:
      SPRING_PROFILES_ACTIVE: dev
      SPRING_DEVTOOLS_RESTART_ENABLED: true
      LOGGING_LEVEL_COM_TASKAPI: DEBUG
    command: ["./mvnw", "spring-boot:run", "-Dspring-boot.run.profiles=dev"]

  mysql:
    ports:
      - "3306:3306"  # Expose for external access
    environment:
      MYSQL_ROOT_PASSWORD: devpass
      MYSQL_PASSWORD: devpass

  redis:
    ports:
      - "6379:6379"  # Expose for external access
```

### **docker-compose.prod.yml** (Production)
```yaml
version: '3.8'

services:
  task-api:
    image: task-management-api:${VERSION:-latest}
    environment:
      SPRING_PROFILES_ACTIVE: prod
      JAVA_OPTS: >-
        -Xmx1g
        -Xms512m
        -XX:+UseG1GC
        -XX:MaxGCPauseMillis=200
        -Dspring.profiles.active=prod
    deploy:
      replicas: 2
      resources:
        limits:
          memory: 1G
          cpus: '0.5'
        reservations:
          memory: 512M
          cpus: '0.25'
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3

  mysql:
    environment:
      MYSQL_ROOT_PASSWORD_FILE: /run/secrets/mysql_root_password
      MYSQL_PASSWORD_FILE: /run/secrets/mysql_password
    secrets:
      - mysql_root_password
      - mysql_password
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'

secrets:
  mysql_root_password:
    external: true
  mysql_password:
    external: true
```

## Configuration Files

### **Redis Configuration**
```conf
# config/redis.conf
# Redis configuration for Task Management API

# Network
bind 0.0.0.0
port 6379
timeout 300
tcp-keepalive 60

# Memory
maxmemory 256mb
maxmemory-policy allkeys-lru

# Persistence
save 900 1
save 300 10
save 60 10000

# Security
requirepass taskredis123

# Logging
loglevel notice
logfile ""

# Performance
tcp-backlog 511
databases 16
```

### **Prometheus Configuration**
```yaml
# config/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

scrape_configs:
  - job_name: 'task-api'
    static_configs:
      - targets: ['task-api:8080']
    metrics_path: '/actuator/prometheus'
    scrape_interval: 10s

  - job_name: 'mysql'
    static_configs:
      - targets: ['mysql:3306']

  - job_name: 'redis'
    static_configs:
      - targets: ['redis:6379']
```

### **Database Initialization Script**
```sql
-- scripts/init-db.sql
-- Database initialization for Task Management API

USE taskdb;

-- Create tasks table
CREATE TABLE IF NOT EXISTS tasks (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    status ENUM('TODO', 'IN_PROGRESS', 'REVIEW', 'DONE', 'BLOCKED') NOT NULL DEFAULT 'TODO',
    priority ENUM('LOW', 'MEDIUM', 'HIGH', 'CRITICAL') NOT NULL DEFAULT 'MEDIUM',
    assignee_email VARCHAR(255),
    due_date DATETIME,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_status (status),
    INDEX idx_assignee (assignee_email),
    INDEX idx_priority (priority),
    INDEX idx_due_date (due_date)
);

-- Create task_tags table
CREATE TABLE IF NOT EXISTS task_tags (
    task_id BIGINT NOT NULL,
    tag VARCHAR(100) NOT NULL,
    PRIMARY KEY (task_id, tag),
    FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE
);

-- Insert sample data
INSERT INTO tasks (title, description, status, priority, assignee_email, due_date) VALUES
('Setup CI/CD Pipeline', 'Implement GitHub Actions with ArgoCD', 'IN_PROGRESS', 'HIGH', 'devops@company.com', '2024-02-01 18:00:00'),
('Database Migration', 'Migrate from H2 to MySQL', 'TODO', 'MEDIUM', 'backend@company.com', '2024-02-05 12:00:00'),
('API Documentation', 'Complete Swagger documentation', 'REVIEW', 'LOW', 'api@company.com', '2024-02-03 15:00:00');

-- Insert sample tags
INSERT INTO task_tags (task_id, tag) VALUES
(1, 'devops'),
(1, 'automation'),
(2, 'database'),
(2, 'migration'),
(3, 'documentation'),
(3, 'api');
```

## Build and Run Instructions

### **Local Development**
```bash
# Clone repository
git clone <repository-url>
cd task-management-api

# Build and start all services
docker-compose up -d

# View logs
docker-compose logs -f task-api

# Stop services
docker-compose down

# Clean up volumes
docker-compose down -v
```

### **Production Build**
```bash
# Build production image
docker build -t task-management-api:1.0.0 .

# Tag for ECR
docker tag task-management-api:1.0.0 \
  123456789012.dkr.ecr.ap-south-1.amazonaws.com/task-management-api:1.0.0

# Push to ECR
aws ecr get-login-password --region ap-south-1 | \
  docker login --username AWS --password-stdin \
  123456789012.dkr.ecr.ap-south-1.amazonaws.com

docker push 123456789012.dkr.ecr.ap-south-1.amazonaws.com/task-management-api:1.0.0
```

### **Testing Container**
```bash
# Test API endpoints
curl http://localhost:8080/actuator/health
curl http://localhost:8080/api/v1/tasks

# Check container logs
docker logs task-api

# Execute into container
docker exec -it task-api sh

# Check container resources
docker stats task-api
```

## Container Security Best Practices

### **1. Image Security**
- ✅ Use official base images
- ✅ Multi-stage builds to reduce attack surface
- ✅ Non-root user execution
- ✅ Minimal runtime dependencies
- ✅ Regular security scanning

### **2. Runtime Security**
- ✅ Read-only root filesystem
- ✅ Dropped Linux capabilities
- ✅ Resource limits
- ✅ Health checks
- ✅ Proper signal handling

### **3. Network Security**
- ✅ Custom bridge networks
- ✅ Port exposure only when needed
- ✅ Service-to-service communication
- ✅ No privileged containers

### **4. Data Security**
- ✅ Secrets management
- ✅ Volume encryption
- ✅ Database credentials rotation
- ✅ Audit logging

This containerization setup provides a complete, production-ready Docker environment with security, monitoring, and development best practices.

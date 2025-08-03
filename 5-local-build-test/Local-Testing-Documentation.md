# Task Management API - Complete Local Testing Documentation

## 📋 Table of Contents
1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [Local Setup and Deployment](#local-setup-and-deployment)
5. [Application Testing](#application-testing)
6. [Monitoring Stack Setup](#monitoring-stack-setup)
7. [Prometheus Configuration](#prometheus-configuration)
8. [Grafana Dashboard Creation](#grafana-dashboard-creation)
9. [Troubleshooting Guide](#troubleshooting-guide)
10. [Complete Workflow Summary](#complete-workflow-summary)

## 🎯 Project Overview

The Task Management API is a Spring Boot REST application that provides CRUD operations for task management. This documentation covers the complete local testing setup including:

- **Spring Boot Application**: REST API with MySQL database
- **Containerization**: Docker and Docker Compose setup
- **Monitoring**: Prometheus metrics collection
- **Visualization**: Grafana dashboards
- **Local Testing**: Complete testing workflow

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Client/User   │───▶│   Task API      │───▶│   MySQL DB      │
│   (curl/browser)│    │   (Port 8080)   │    │   (Port 3306)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │   Prometheus    │
                       │   (Port 9090)   │
                       │   Metrics       │
                       └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │   Grafana       │
                       │   (Port 3000)   │
                       │   Dashboards    │
                       └─────────────────┘
```

### Component Details:
- **Task API**: Spring Boot application exposing REST endpoints
- **MySQL**: Database for persistent task storage
- **Prometheus**: Metrics collection and storage
- **Grafana**: Metrics visualization and dashboards

## 📋 Prerequisites

### Software Requirements:
- **Docker**: Version 20.10+
- **Docker Compose**: Version 2.0+
- **System Resources**: 4GB+ RAM, 10GB+ disk space
- **Network Ports**: 3000, 3306, 8080, 9090 available

### Verification Commands:
```bash
# Check Docker installation
docker --version
docker-compose --version

# Check available ports
sudo netstat -tulpn | grep -E ':(3000|3306|8080|9090)'
```

## 🚀 Local Setup and Deployment

### Project Structure:
```
RestAPI-Task-Management-Demo/
├── 2-source-code/              # Spring Boot source code
│   ├── src/main/java/          # Java application code
│   ├── src/main/resources/     # Configuration files
│   ├── pom.xml                 # Maven dependencies
│   └── Dockerfile              # Application container image
└── 4-containerization/         # Docker deployment
    ├── docker-compose.yml      # Multi-service orchestration
    ├── monitoring/             # Monitoring configuration
    │   └── prometheus.yml      # Prometheus scrape config
    └── README.md              # Documentation
```

### Step 1: Build Application Image
```bash
# Navigate to source code directory
cd RestAPI-Task-Management-Demo/2-source-code

# Build Docker image
sudo docker build -t task-management-api .
```

**What happens during build:**
- Multi-stage Docker build process
- Stage 1: Compile Java application with Maven
- Stage 2: Create runtime image with JRE
- Result: Optimized container image (~265MB)

### Step 2: Start Services with Docker Compose
```bash
# Navigate to containerization directory
cd ../4-containerization

# Start all services
sudo docker compose up -d
```

**Services Started:**
1. **MySQL Database** (`task-mysql`)
   - Port: 3306
   - Database: `taskdb`
   - User: `taskuser` / Password: `taskpass`

2. **Task Management API** (`task-api`)
   - Port: 8080
   - Depends on MySQL health check
   - Exposes metrics at `/actuator/prometheus`

3. **Prometheus** (`task-prometheus`)
   - Port: 9090
   - Scrapes metrics from Task API
   - Stores time-series data

4. **Grafana** (`task-grafana`)
   - Port: 3000
   - Username: `admin` / Password: `admin123`
   - Visualizes Prometheus metrics

### Step 3: Verify Deployment
```bash
# Check all containers are running
sudo docker compose ps

# Expected output:
# NAME             IMAGE                    STATUS
# task-api         task-management-api      Up (healthy)
# task-grafana     grafana/grafana:latest   Up
# task-mysql       mysql:8.0                Up (healthy)
# task-prometheus  prom/prometheus:latest   Up
```

## 🧪 Application Testing

### Health Check Verification
```bash
# Application health check
curl http://localhost:8080/actuator/health

# Expected response:
{
  "status": "UP",
  "components": {
    "db": {"status": "UP"},
    "diskSpace": {"status": "UP"},
    "ping": {"status": "UP"}
  }
}
```

### API Endpoint Testing

#### 1. Get All Tasks (Initially Empty)
```bash
curl http://localhost:8080/api/tasks

# Expected response: []
```

#### 2. Create New Task
```bash
curl -X POST http://localhost:8080/api/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Complete DevOps Project",
    "description": "Set up monitoring and testing",
    "status": "PENDING"
  }'

# Expected response:
{
  "id": 1,
  "title": "Complete DevOps Project",
  "description": "Set up monitoring and testing",
  "status": "PENDING",
  "createdAt": "2024-01-15T10:30:00",
  "updatedAt": "2024-01-15T10:30:00"
}
```

#### 3. Get Specific Task
```bash
curl http://localhost:8080/api/tasks/1

# Returns the created task details
```

#### 4. Update Task
```bash
curl -X PUT http://localhost:8080/api/tasks/1 \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Complete DevOps Project",
    "description": "Set up monitoring and testing",
    "status": "COMPLETED"
  }'
```

#### 5. Delete Task
```bash
curl -X DELETE http://localhost:8080/api/tasks/1

# Expected response: 204 No Content
```

### Database Verification
```bash
# Connect to MySQL database
sudo docker exec -it task-mysql mysql -u taskuser -p taskdb
# Password: taskpass

# Inside MySQL console:
SHOW TABLES;
SELECT * FROM tasks;
DESCRIBE tasks;
EXIT;
```

## 📊 Monitoring Stack Setup

### Understanding the Monitoring Flow

```
Task API ──metrics──▶ Prometheus ──data──▶ Grafana ──dashboards──▶ User
   │                      │                    │
   │                      │                    │
   ▼                      ▼                    ▼
/actuator/prometheus   :9090/metrics      :3000/dashboards
```

### Metrics Exposed by Task API

The Spring Boot application automatically exposes metrics at `/actuator/prometheus`:

```bash
# View all available metrics
curl http://localhost:8080/actuator/prometheus

# Key metrics include:
# - http_server_requests_seconds_count: Request count
# - http_server_requests_seconds_sum: Response time sum
# - jvm_memory_used_bytes: JVM memory usage
# - system_cpu_usage: CPU utilization
# - hikaricp_connections_*: Database connection pool
```

### Metric Categories:

#### 1. Application Metrics
- **Request Count**: `http_server_requests_seconds_count`
- **Response Time**: `http_server_requests_seconds_sum`
- **Error Rate**: Requests with status 4xx/5xx

#### 2. JVM Metrics
- **Memory Usage**: `jvm_memory_used_bytes{area="heap"}`
- **Garbage Collection**: `jvm_gc_pause_seconds_count`
- **Thread Count**: `jvm_threads_live_threads`

#### 3. System Metrics
- **CPU Usage**: `system_cpu_usage`
- **Disk Space**: `disk_free_bytes`
- **Process Uptime**: `process_uptime_seconds`

#### 4. Database Metrics
- **Active Connections**: `hikaricp_connections_active`
- **Connection Pool Usage**: `hikaricp_connections_usage`
- **Connection Acquire Time**: `hikaricp_connections_acquire_seconds`

## 🔧 Prometheus Configuration

### Initial Configuration Issue
By default, Prometheus only scrapes itself. We need to configure it to scrape our Task API.

### Step 1: Create Prometheus Configuration
```bash
# Create monitoring directory
mkdir -p monitoring

# Create Prometheus configuration
cat > monitoring/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
  
  - job_name: 'task-management-api'
    static_configs:
      - targets: ['app:8080']
    metrics_path: '/actuator/prometheus'
    scrape_interval: 30s
EOF
```

### Step 2: Apply Configuration to Running Container
```bash
# Copy configuration to Prometheus container
sudo docker cp monitoring/prometheus.yml task-prometheus:/etc/prometheus/prometheus.yml

# Restart Prometheus to reload configuration
sudo docker restart task-prometheus

# Wait for restart
sleep 30
```

### Step 3: Verify Configuration
```bash
# Check if configuration is loaded
sudo docker exec task-prometheus cat /etc/prometheus/prometheus.yml

# Should show your custom configuration with task-management-api job
```

### Step 4: Verify Targets
1. Open Prometheus UI: http://localhost:9090
2. Go to **Status** → **Targets**
3. Verify both targets are **UP**:
   - `prometheus` (localhost:9090)
   - `task-management-api` (app:8080)

### Prometheus Query Examples

#### Basic Queries:
```promql
# Check if metrics are available
up

# Application uptime
up{job="task-management-api"}

# Total request count
http_server_requests_seconds_count

# JVM memory usage
jvm_memory_used_bytes{area="heap"}
```

#### Advanced Queries:
```promql
# Request rate (requests per second)
rate(http_server_requests_seconds_count[5m])

# Average response time
http_server_requests_seconds_sum / http_server_requests_seconds_count

# Error rate percentage
rate(http_server_requests_seconds_count{status=~"5.."}[5m]) / rate(http_server_requests_seconds_count[5m]) * 100

# Memory usage by heap area
sum by (id) (jvm_memory_used_bytes{area="heap"})
```

## 📈 Grafana Dashboard Creation

### Step 1: Access Grafana
- **URL**: http://localhost:3000
- **Username**: `admin`
- **Password**: `admin123`

### Step 2: Add Prometheus Data Source
1. Click **Configuration** (gear icon) → **Data Sources**
2. Click **Add data source**
3. Select **Prometheus**
4. Configure:
   - **Name**: `prometheus`
   - **URL**: `http://task-prometheus:9090`
   - **Access**: `Server (default)`
5. Click **Save & Test**
6. Verify green checkmark: "Data source is working"

### Step 3: Create Dashboard
1. Click **+** (plus icon) → **Dashboard**
2. Click **Add new panel**

### Step 4: Create Panels

#### Panel 1: API Request Rate
- **Query**: `sum(rate(http_server_requests_seconds_count[5m]))`
- **Title**: "API Request Rate"
- **Unit**: Field → Unit → Throughput → "requests/sec"
- **Visualization**: Time series
- Click **Apply**

#### Panel 2: JVM Memory Usage
- Click **Add panel**
- **Query**: `jvm_memory_used_bytes{area="heap"}`
- **Title**: "JVM Memory Usage"
- **Unit**: Field → Unit → Data → "bytes"
- **Visualization**: Time series
- Click **Apply**

#### Panel 3: Response Time
- Click **Add panel**
- **Query**: `http_server_requests_seconds_sum / http_server_requests_seconds_count`
- **Title**: "Average Response Time"
- **Unit**: Field → Unit → Time → "seconds"
- **Visualization**: Stat
- Click **Apply**

#### Panel 4: Database Connections
- Click **Add panel**
- **Query**: `hikaricp_connections_active`
- **Title**: "Active Database Connections"
- **Unit**: Field → Unit → Short → "short"
- **Visualization**: Gauge
- Click **Apply**

### Step 5: Save Dashboard
1. Click **Save** (disk icon)
2. **Dashboard name**: "Task Management API Monitoring"
3. **Folder**: General
4. Click **Save**

### Step 6: Generate Test Data
```bash
# Create script to generate API traffic
cat > generate_traffic.sh << 'EOF'
#!/bin/bash
for i in {1..20}; do
  # Create task
  curl -X POST http://localhost:8080/api/tasks \
    -H "Content-Type: application/json" \
    -d "{\"title\":\"Load Test Task $i\",\"description\":\"Testing metrics\"}"
  
  # Get all tasks
  curl http://localhost:8080/api/tasks
  
  # Health check
  curl http://localhost:8080/actuator/health
  
  sleep 2
done
EOF

chmod +x generate_traffic.sh
./generate_traffic.sh
```

### Dashboard Features

#### Time Range Selection
- **Default**: Last 6 hours
- **Options**: 5m, 15m, 30m, 1h, 6h, 12h, 24h
- **Custom**: Set specific date/time ranges

#### Auto-Refresh
- **Options**: Off, 5s, 10s, 30s, 1m, 5m, 15m, 30m, 1h
- **Recommended**: 30s for real-time monitoring

#### Panel Interactions
- **Zoom**: Click and drag on time series
- **Legend**: Click to hide/show series
- **Tooltip**: Hover for detailed values
- **Full Screen**: Click panel title → View

## 🔍 Troubleshooting Guide

### Common Issues and Solutions

#### 1. Containers Not Starting
**Problem**: `docker compose ps` shows containers as "Exited"

**Diagnosis**:
```bash
# Check container logs
sudo docker compose logs mysql
sudo docker compose logs app
sudo docker compose logs prometheus
sudo docker compose logs grafana
```

**Solutions**:
- **Port conflicts**: Change ports in docker-compose.yml
- **Resource issues**: Increase Docker memory allocation
- **Permission issues**: Check file permissions

#### 2. Application Health Check Failing
**Problem**: `curl http://localhost:8080/actuator/health` returns connection refused

**Diagnosis**:
```bash
# Check if container is running
sudo docker ps | grep task-api

# Check application logs
sudo docker logs task-api

# Check if port is bound
sudo netstat -tulpn | grep :8080
```

**Solutions**:
- Wait for application startup (can take 60-90 seconds)
- Check database connectivity
- Verify environment variables

#### 3. Database Connection Issues
**Problem**: Application shows database connection errors

**Diagnosis**:
```bash
# Check MySQL container
sudo docker logs task-mysql

# Test database connectivity
sudo docker exec task-api nc -zv mysql 3306

# Check database credentials
sudo docker exec -it task-mysql mysql -u taskuser -p taskdb
```

**Solutions**:
- Verify MySQL is healthy: `sudo docker compose ps`
- Check environment variables in docker-compose.yml
- Ensure proper startup order with `depends_on`

#### 4. Prometheus Not Scraping Metrics
**Problem**: Prometheus targets show as "DOWN" or no metrics available

**Diagnosis**:
```bash
# Check Prometheus targets
curl http://localhost:9090/api/v1/targets

# Verify metrics endpoint
curl http://localhost:8080/actuator/prometheus

# Check Prometheus configuration
sudo docker exec task-prometheus cat /etc/prometheus/prometheus.yml
```

**Solutions**:
- Copy correct configuration: `sudo docker cp monitoring/prometheus.yml task-prometheus:/etc/prometheus/prometheus.yml`
- Restart Prometheus: `sudo docker restart task-prometheus`
- Verify network connectivity between containers

#### 5. Grafana Data Source Connection Failed
**Problem**: "Data source is not working" error in Grafana

**Diagnosis**:
```bash
# Check if Grafana can reach Prometheus
sudo docker exec task-grafana ping task-prometheus

# Check Prometheus is responding
curl http://localhost:9090/api/v1/query?query=up
```

**Solutions**:
- Use correct URL: `http://task-prometheus:9090`
- Verify both containers are on same network
- Check Prometheus is running and healthy

#### 6. No Data in Grafana Panels
**Problem**: Panels show "No data" despite correct queries

**Diagnosis**:
- Check time range (last 6 hours by default)
- Verify metrics exist in Prometheus
- Generate API traffic to create metrics

**Solutions**:
```bash
# Generate test data
curl http://localhost:8080/api/tasks
curl -X POST http://localhost:8080/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"title":"Test","description":"Generate metrics"}'

# Wait 1-2 minutes for metrics to appear
# Refresh Grafana dashboard
```

### Performance Optimization

#### Container Resource Allocation
```yaml
# Add to docker-compose.yml services
deploy:
  resources:
    limits:
      memory: 1G
      cpus: '0.5'
    reservations:
      memory: 512M
      cpus: '0.25'
```

#### JVM Tuning
```yaml
# Environment variables for Task API
environment:
  - JAVA_OPTS=-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -XX:+UseG1GC
```

#### Database Optimization
```yaml
# MySQL environment variables
environment:
  - MYSQL_INNODB_BUFFER_POOL_SIZE=512M
  - MYSQL_MAX_CONNECTIONS=100
```

## 📋 Complete Workflow Summary

### Initial Setup (One-time)
1. **Build Application Image**:
   ```bash
   cd 2-source-code
   sudo docker build -t task-management-api .
   ```

2. **Start Services**:
   ```bash
   cd ../4-containerization
   sudo docker compose up -d
   ```

3. **Configure Prometheus**:
   ```bash
   mkdir -p monitoring
   # Create prometheus.yml configuration
   sudo docker cp monitoring/prometheus.yml task-prometheus:/etc/prometheus/prometheus.yml
   sudo docker restart task-prometheus
   ```

4. **Setup Grafana**:
   - Access: http://localhost:3000 (admin/admin123)
   - Add Prometheus data source: http://task-prometheus:9090
   - Create dashboard with monitoring panels

### Daily Testing Workflow
1. **Verify Services**:
   ```bash
   sudo docker compose ps
   curl http://localhost:8080/actuator/health
   ```

2. **Test API Endpoints**:
   ```bash
   # CRUD operations testing
   curl http://localhost:8080/api/tasks
   # Create, update, delete tasks
   ```

3. **Monitor Metrics**:
   - Prometheus: http://localhost:9090
   - Grafana: http://localhost:3000
   - Check dashboards for real-time metrics

4. **Generate Load for Testing**:
   ```bash
   # Run traffic generation script
   ./generate_traffic.sh
   ```

### Maintenance Commands
```bash
# View logs
sudo docker compose logs -f app

# Restart specific service
sudo docker compose restart app

# Update application
sudo docker build -t task-management-api .
sudo docker compose up -d

# Backup database
sudo docker exec task-mysql mysqldump -u taskuser -p taskdb > backup.sql

# Cleanup
sudo docker compose down -v
sudo docker system prune -f
```

### Success Verification Checklist
- [ ] All containers running: `sudo docker compose ps`
- [ ] Application healthy: `curl http://localhost:8080/actuator/health`
- [ ] API endpoints working: CRUD operations successful
- [ ] Database connected: MySQL status in health check
- [ ] Prometheus scraping: Targets UP at http://localhost:9090/targets
- [ ] Metrics available: Queries return data in Prometheus
- [ ] Grafana connected: Data source test successful
- [ ] Dashboards working: Panels showing real-time data

## 🎯 Key Learning Outcomes

### Technical Skills Demonstrated
1. **Containerization**: Docker multi-stage builds, Docker Compose orchestration
2. **Monitoring**: Prometheus metrics collection, Grafana visualization
3. **Spring Boot**: REST API development, Actuator endpoints
4. **Database Integration**: MySQL connectivity, connection pooling
5. **DevOps Practices**: Health checks, logging, configuration management

### Monitoring Best Practices
1. **Metrics Collection**: Comprehensive application and infrastructure metrics
2. **Visualization**: Clear, actionable dashboards
3. **Alerting**: Threshold-based monitoring (can be extended)
4. **Performance**: Resource utilization tracking
5. **Troubleshooting**: Systematic debugging approach

### Production Readiness
This local setup demonstrates production-ready practices:
- Health checks and graceful startup
- Metrics-driven monitoring
- Containerized deployment
- Configuration management
- Database persistence
- Security considerations (non-root containers)

This comprehensive setup provides a solid foundation for understanding modern application monitoring and observability practices in a containerized environment.

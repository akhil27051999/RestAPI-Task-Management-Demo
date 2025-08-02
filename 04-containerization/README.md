# Containerization - Docker Setup

Complete containerization strategy for the Task Management API with production-ready Docker configurations.

## Container Strategy Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    CONTAINERIZATION STRATEGY                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                 MULTI-STAGE BUILD                       │    │
│  │                                                         │    │
│  │  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐  │    │
│  │  │   Stage 1   │───▶│   Stage 2  │───▶│   Stage 3   │  │    │
│  │  │    Build    │    │    Test     │    │   Runtime   │  │    │
│  │  │             │    │             │    │             │  │    │
│  │  │ Maven Build │    │ Run Tests   │    │ Final Image │  │    │
│  │  │ Dependencies│    │ Security    │    │ Minimal     │  │    │
│  │  └─────────────┘    └─────────────┘    └─────────────┘  │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                LOCAL DEVELOPMENT                        │    │
│  │                                                         │    │
│  │  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐  │    │
│  │  │ Task API    │    │   MySQL     │    │   Redis     │  │    │
│  │  │ Container   │    │ Container   │    │ Container   │  │    │
│  │  │             │    │             │    │             │  │    │
│  │  └─────────────┘    └─────────────┘    └─────────────┘  │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

# Build & Dependency Management Files

## Usage Instructions

### Build Application
```bash
# Build with Maven
mvn clean package

# Build Docker image
docker build -t task-management-api:latest .
```

### Run Locally
```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f app

# Stop services
docker-compose down
```

### Access Application
- **API**: http://localhost:8080/api/tasks
- **Health Check**: http://localhost:8080/actuator/health
- **Metrics**: http://localhost:8080/actuator/prometheus
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3000 (admin/admin123)

### Database Access
```bash
# Connect to MySQL
docker exec -it task-management-mysql mysql -u taskuser -p taskdb
```

This configuration provides everything needed for local development and containerized deployment.


# Monitoring & Observability Stack

## Overview
Complete monitoring and observability solution for the Task Management API including metrics collection, visualization, logging, and load testing.

## Components

### Metrics & Monitoring
- **Prometheus**: Metrics collection and alerting
- **Grafana**: Visualization and dashboards
- **Loki**: Log aggregation (alternative to ELK)

### Logging (ELK Stack)
- **Elasticsearch**: Search and analytics engine
- **Logstash**: Log processing pipeline
- **Kibana**: Log visualization and analysis

### Load Testing
- **Locust**: Python-based load testing
- **K6**: JavaScript-based performance testing

## Quick Start

### Deploy Monitoring Stack
```bash
# Create monitoring namespace
kubectl create namespace monitoring

# Deploy Prometheus
kubectl apply -f prometheus/

# Deploy Grafana
kubectl apply -f grafana/

# Deploy Loki (optional - alternative to ELK)
kubectl apply -f loki/

# Deploy ELK Stack (optional - alternative to Loki)
kubectl apply -f elk-stack/

# Deploy Load Testing Tools
kubectl apply -f load-testing/locust/
```

### Access Services
- **Prometheus**: http://prometheus.taskmanagement.local
- **Grafana**: http://grafana.taskmanagement.local (admin/admin123)
- **Kibana**: http://kibana.taskmanagement.local
- **Locust**: http://locust.taskmanagement.local

### Run Load Tests
```bash
# K6 load test
k6 run load-testing/k6/load-test.js

# With custom target
TARGET_HOST=http://your-api.com k6 run load-testing/k6/load-test.js
```

## Configuration

### Prometheus Targets
- Task Management API: `/actuator/prometheus`
- Kubernetes nodes and pods
- Custom application metrics

### Grafana Dashboards
- Application performance metrics
- JVM memory and CPU usage
- Request rates and error rates
- Response time percentiles

### Alerting Rules
- High error rate (>5%)
- High response time (>2s)
- Application down
- High memory usage

## Monitoring Best Practices
- Set up proper alerting thresholds
- Monitor business metrics
- Use structured logging
- Implement distributed tracing
- Regular load testing
- Monitor infrastructure metrics

This monitoring stack provides comprehensive observability for production environments with proper alerting and performance testing capabilities.


## Deployment Commands

### Deploy All Monitoring Components
```bash
# Create namespace
kubectl create namespace monitoring

# Deploy Prometheus stack
kubectl apply -f 8-monitoring/prometheus/

# Deploy Grafana
kubectl apply -f 8-monitoring/grafana/

# Deploy ELK stack
kubectl apply -f 8-monitoring/elk-stack/

# Deploy load testing
kubectl apply -f 8-monitoring/load-testing/locust/
```

### Run Load Tests
```bash
# K6 load test
k6 run 8-monitoring/load-testing/k6/load-test.js

# Locust via web interface
open http://locust.taskmanagement.local
```

This monitoring setup provides comprehensive observability with metrics, logging, visualization, and performance testing capabilities for production environments.

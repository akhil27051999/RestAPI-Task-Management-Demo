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

## Deployment Commands

```bash
# Deploy monitoring stack
kubectl apply -f 9-monitoring/prometheus/
kubectl apply -f 9-monitoring/grafana/
kubectl apply -f 9-monitoring/loki/
kubectl apply -f 9-monitoring/elk-stack/

# Deploy load testing
kubectl apply -f 9-monitoring/load-testing/locust/

# Run K6 load test
k6 run 9-monitoring/load-testing/k6/load-test.js
```

## Access URLs
- Prometheus: http://prometheus-service:9090
- Grafana: http://grafana-service:3000 (admin/admin123)
- Kibana: http://kibana-service:5601
- Locust: http://locust-service:8089

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

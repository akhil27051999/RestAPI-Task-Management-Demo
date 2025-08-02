# Section 9: Monitoring & Observability

## Overview
Complete monitoring and observability stack using Prometheus, Grafana, ELK Stack, and AWS CloudWatch for comprehensive application and infrastructure monitoring.

## Directory Structure
```
9-monitoring-observability/
├── prometheus/
│   ├── helm-values/
│   │   ├── prometheus-values.yaml
│   │   └── alertmanager-values.yaml
│   ├── rules/
│   │   ├── application-rules.yaml
│   │   ├── infrastructure-rules.yaml
│   │   └── kubernetes-rules.yaml
│   └── targets/
│       └── service-monitors.yaml
├── grafana/
│   ├── helm-values/
│   │   └── grafana-values.yaml
│   ├── dashboards/
│   │   ├── application-dashboard.json
│   │   ├── infrastructure-dashboard.json
│   │   ├── kubernetes-dashboard.json
│   │   └── business-metrics-dashboard.json
│   └── datasources/
│       └── datasources.yaml
├── elk-stack/
│   ├── elasticsearch/
│   │   ├── elasticsearch-values.yaml
│   │   └── index-templates/
│   │       └── application-logs.json
│   ├── logstash/
│   │   ├── logstash-values.yaml
│   │   └── pipelines/
│   │       ├── application-pipeline.conf
│   │       └── kubernetes-pipeline.conf
│   ├── kibana/
│   │   ├── kibana-values.yaml
│   │   └── dashboards/
│   │       ├── application-logs-dashboard.json
│   │       └── error-analysis-dashboard.json
│   └── filebeat/
│       ├── filebeat-values.yaml
│       └── config/
│           └── filebeat.yml
├── jaeger/
│   ├── jaeger-values.yaml
│   └── config/
│       └── jaeger-config.yaml
├── cloudwatch/
│   ├── log-groups.yaml
│   ├── custom-metrics.yaml
│   └── alarms/
│       ├── application-alarms.yaml
│       ├── infrastructure-alarms.yaml
│       └── cost-alarms.yaml
├── alerts/
│   ├── slack-webhook.yaml
│   ├── pagerduty-config.yaml
│   └── email-notifications.yaml
└── scripts/
    ├── deploy-monitoring.sh
    ├── setup-dashboards.sh
    ├── test-alerts.sh
    └── backup-configs.sh
```

## Prometheus Configuration

### Prometheus Helm Values
```yaml
# prometheus/helm-values/prometheus-values.yaml
prometheus:
  prometheusSpec:
    retention: 30d
    retentionSize: 50GB
    
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: gp3
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 100Gi
    
    resources:
      requests:
        memory: 2Gi
        cpu: 1000m
      limits:
        memory: 4Gi
        cpu: 2000m
    
    additionalScrapeConfigs:
      - job_name: 'task-management-api'
        kubernetes_sd_configs:
          - role: endpoints
            namespaces:
              names:
                - task-management-dev
                - task-management-staging
                - task-management-prod
        relabel_configs:
          - source_labels: [__meta_kubernetes_service_name]
            action: keep
            regex: task-management-service
          - source_labels: [__meta_kubernetes_endpoint_port_name]
            action: keep
            regex: http
        metrics_path: /actuator/prometheus
        scrape_interval: 30s
    
    ruleSelector:
      matchLabels:
        app: kube-prometheus-stack
        release: prometheus

alertmanager:
  alertmanagerSpec:
    storage:
      volumeClaimTemplate:
        spec:
          storageClassName: gp3
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 10Gi
    
    resources:
      requests:
        memory: 256Mi
        cpu: 100m
      limits:
        memory: 512Mi
        cpu: 200m

grafana:
  enabled: true
  adminPassword: "admin123"
  
  persistence:
    enabled: true
    storageClassName: gp3
    size: 10Gi
  
  resources:
    requests:
      memory: 256Mi
      cpu: 100m
    limits:
      memory: 512Mi
      cpu: 200m
  
  ingress:
    enabled: true
    ingressClassName: nginx
    hosts:
      - grafana.taskmanagement.local
    tls:
      - secretName: grafana-tls
        hosts:
          - grafana.taskmanagement.local

kubeStateMetrics:
  enabled: true

nodeExporter:
  enabled: true

prometheusOperator:
  enabled: true
```

### Application Monitoring Rules
```yaml
# prometheus/rules/application-rules.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: task-management-application-rules
  namespace: monitoring
  labels:
    app: kube-prometheus-stack
    release: prometheus
spec:
  groups:
  - name: task-management.application
    rules:
    - alert: HighErrorRate
      expr: |
        (
          rate(http_server_requests_seconds_count{status=~"5.."}[5m]) /
          rate(http_server_requests_seconds_count[5m])
        ) * 100 > 5
      for: 5m
      labels:
        severity: warning
        service: task-management-api
      annotations:
        summary: "High error rate detected"
        description: "Error rate is {{ $value }}% for {{ $labels.instance }}"
    
    - alert: HighResponseTime
      expr: |
        histogram_quantile(0.95, 
          rate(http_server_requests_seconds_bucket[5m])
        ) > 2
      for: 5m
      labels:
        severity: warning
        service: task-management-api
      annotations:
        summary: "High response time detected"
        description: "95th percentile response time is {{ $value }}s for {{ $labels.instance }}"
    
    - alert: DatabaseConnectionPoolExhausted
      expr: |
        hikaricp_connections_active / hikaricp_connections_max > 0.8
      for: 2m
      labels:
        severity: critical
        service: task-management-api
      annotations:
        summary: "Database connection pool nearly exhausted"
        description: "Connection pool usage is {{ $value | humanizePercentage }} for {{ $labels.instance }}"
    
    - alert: HighMemoryUsage
      expr: |
        (jvm_memory_used_bytes{area="heap"} / jvm_memory_max_bytes{area="heap"}) * 100 > 85
      for: 5m
      labels:
        severity: warning
        service: task-management-api
      annotations:
        summary: "High JVM heap memory usage"
        description: "JVM heap usage is {{ $value }}% for {{ $labels.instance }}"
    
    - alert: ApplicationDown
      expr: |
        up{job="task-management-api"} == 0
      for: 1m
      labels:
        severity: critical
        service: task-management-api
      annotations:
        summary: "Application is down"
        description: "Task Management API instance {{ $labels.instance }} is down"
```

### Infrastructure Monitoring Rules
```yaml
# prometheus/rules/infrastructure-rules.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: infrastructure-rules
  namespace: monitoring
  labels:
    app: kube-prometheus-stack
    release: prometheus
spec:
  groups:
  - name: infrastructure.nodes
    rules:
    - alert: NodeHighCPUUsage
      expr: |
        (1 - rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100 > 80
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High CPU usage on node"
        description: "CPU usage is {{ $value }}% on {{ $labels.instance }}"
    
    - alert: NodeHighMemoryUsage
      expr: |
        (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High memory usage on node"
        description: "Memory usage is {{ $value }}% on {{ $labels.instance }}"
    
    - alert: NodeDiskSpaceLow
      expr: |
        (1 - (node_filesystem_avail_bytes{fstype!="tmpfs"} / node_filesystem_size_bytes{fstype!="tmpfs"})) * 100 > 85
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "Low disk space on node"
        description: "Disk usage is {{ $value }}% on {{ $labels.instance }} mount {{ $labels.mountpoint }}"
    
    - alert: PodCrashLooping
      expr: |
        rate(kube_pod_container_status_restarts_total[15m]) > 0
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "Pod is crash looping"
        description: "Pod {{ $labels.namespace }}/{{ $labels.pod }} is crash looping"
```

### Service Monitors
```yaml
# prometheus/targets/service-monitors.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: task-management-api
  namespace: monitoring
  labels:
    app: task-management-api
spec:
  selector:
    matchLabels:
      app: task-management-api
  namespaceSelector:
    matchNames:
      - task-management-dev
      - task-management-staging
      - task-management-prod
  endpoints:
  - port: http
    path: /actuator/prometheus
    interval: 30s
    scrapeTimeout: 10s
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: mysql-exporter
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: mysql-exporter
  endpoints:
  - port: metrics
    interval: 30s
```

## Grafana Configuration

### Grafana Helm Values
```yaml
# grafana/helm-values/grafana-values.yaml
adminUser: admin
adminPassword: admin123

persistence:
  enabled: true
  storageClassName: gp3
  size: 10Gi

resources:
  requests:
    memory: 256Mi
    cpu: 100m
  limits:
    memory: 512Mi
    cpu: 200m

ingress:
  enabled: true
  ingressClassName: nginx
  hosts:
    - grafana.taskmanagement.local
  tls:
    - secretName: grafana-tls
      hosts:
        - grafana.taskmanagement.local

datasources:
  datasources.yaml:
    apiVersion: 1
    datasources:
    - name: Prometheus
      type: prometheus
      url: http://prometheus-server:80
      access: proxy
      isDefault: true
    - name: Elasticsearch
      type: elasticsearch
      url: http://elasticsearch:9200
      access: proxy
      database: "logstash-*"
      timeField: "@timestamp"
    - name: Jaeger
      type: jaeger
      url: http://jaeger-query:16686
      access: proxy

dashboardProviders:
  dashboardproviders.yaml:
    apiVersion: 1
    providers:
    - name: 'default'
      orgId: 1
      folder: ''
      type: file
      disableDeletion: false
      editable: true
      options:
        path: /var/lib/grafana/dashboards/default

dashboards:
  default:
    application-metrics:
      gnetId: 12900
      revision: 1
      datasource: Prometheus
    kubernetes-cluster:
      gnetId: 7249
      revision: 1
      datasource: Prometheus
    jvm-metrics:
      gnetId: 4701
      revision: 6
      datasource: Prometheus

plugins:
  - grafana-piechart-panel
  - grafana-worldmap-panel
  - grafana-clock-panel

env:
  GF_FEATURE_TOGGLES_ENABLE: "tempoSearch,tempoBackendSearch"
  GF_INSTALL_PLUGINS: "grafana-piechart-panel,grafana-worldmap-panel"
```

### Application Dashboard
```json
{
  "dashboard": {
    "id": null,
    "title": "Task Management API - Application Metrics",
    "tags": ["task-management", "application"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "Request Rate",
        "type": "stat",
        "targets": [
          {
            "expr": "sum(rate(http_server_requests_seconds_count{job=\"task-management-api\"}[5m]))",
            "legendFormat": "Requests/sec"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "reqps"
          }
        },
        "gridPos": {"h": 8, "w": 6, "x": 0, "y": 0}
      },
      {
        "id": 2,
        "title": "Error Rate",
        "type": "stat",
        "targets": [
          {
            "expr": "sum(rate(http_server_requests_seconds_count{job=\"task-management-api\",status=~\"5..\"}[5m])) / sum(rate(http_server_requests_seconds_count{job=\"task-management-api\"}[5m])) * 100",
            "legendFormat": "Error %"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "thresholds": {
              "steps": [
                {"color": "green", "value": null},
                {"color": "yellow", "value": 1},
                {"color": "red", "value": 5}
              ]
            }
          }
        },
        "gridPos": {"h": 8, "w": 6, "x": 6, "y": 0}
      },
      {
        "id": 3,
        "title": "Response Time (95th percentile)",
        "type": "stat",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, sum(rate(http_server_requests_seconds_bucket{job=\"task-management-api\"}[5m])) by (le))",
            "legendFormat": "95th percentile"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "s"
          }
        },
        "gridPos": {"h": 8, "w": 6, "x": 12, "y": 0}
      },
      {
        "id": 4,
        "title": "Active Database Connections",
        "type": "stat",
        "targets": [
          {
            "expr": "sum(hikaricp_connections_active{job=\"task-management-api\"})",
            "legendFormat": "Active Connections"
          }
        ],
        "gridPos": {"h": 8, "w": 6, "x": 18, "y": 0}
      },
      {
        "id": 5,
        "title": "JVM Memory Usage",
        "type": "timeseries",
        "targets": [
          {
            "expr": "jvm_memory_used_bytes{job=\"task-management-api\",area=\"heap\"}",
            "legendFormat": "Heap Used - {{instance}}"
          },
          {
            "expr": "jvm_memory_max_bytes{job=\"task-management-api\",area=\"heap\"}",
            "legendFormat": "Heap Max - {{instance}}"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "bytes"
          }
        },
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 8}
      },
      {
        "id": 6,
        "title": "HTTP Request Duration",
        "type": "heatmap",
        "targets": [
          {
            "expr": "sum(rate(http_server_requests_seconds_bucket{job=\"task-management-api\"}[5m])) by (le)",
            "format": "heatmap",
            "legendFormat": "{{le}}"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 8}
      }
    ],
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "refresh": "30s"
  }
}
```

## ELK Stack Configuration

### Elasticsearch Values
```yaml
# elk-stack/elasticsearch/elasticsearch-values.yaml
clusterName: "task-management-logs"
nodeGroup: "master"

roles:
  master: "true"
  ingest: "true"
  data: "true"

replicas: 3
minimumMasterNodes: 2

esMajorVersion: ""

esConfig:
  elasticsearch.yml: |
    cluster.name: task-management-logs
    network.host: 0.0.0.0
    discovery.seed_hosts: "elasticsearch-master-headless"
    cluster.initial_master_nodes: "elasticsearch-master-0,elasticsearch-master-1,elasticsearch-master-2"
    xpack.security.enabled: false
    xpack.monitoring.collection.enabled: true

volumeClaimTemplate:
  accessModes: ["ReadWriteOnce"]
  storageClassName: gp3
  resources:
    requests:
      storage: 100Gi

resources:
  requests:
    cpu: "1000m"
    memory: "2Gi"
  limits:
    cpu: "2000m"
    memory: "4Gi"

esJavaOpts: "-Xmx2g -Xms2g"

service:
  type: ClusterIP
  ports:
    - name: http
      port: 9200
      protocol: TCP
    - name: transport
      port: 9300
      protocol: TCP
```

### Logstash Configuration
```yaml
# elk-stack/logstash/logstash-values.yaml
replicas: 2

logstashConfig:
  logstash.yml: |
    http.host: "0.0.0.0"
    xpack.monitoring.elasticsearch.hosts: ["http://elasticsearch:9200"]

logstashPipeline:
  logstash.conf: |
    input {
      beats {
        port => 5044
      }
    }
    
    filter {
      if [kubernetes][container][name] == "task-management-api" {
        grok {
          match => { "message" => "%{TIMESTAMP_ISO8601:timestamp} %{LOGLEVEL:level} %{DATA:thread} %{DATA:logger} - %{GREEDYDATA:message}" }
          overwrite => [ "message" ]
        }
        
        date {
          match => [ "timestamp", "yyyy-MM-dd HH:mm:ss.SSS" ]
        }
        
        if [level] == "ERROR" {
          mutate {
            add_tag => [ "error" ]
          }
        }
      }
      
      if [kubernetes][namespace] {
        mutate {
          add_field => { "environment" => "%{[kubernetes][namespace]}" }
        }
      }
    }
    
    output {
      elasticsearch {
        hosts => ["elasticsearch:9200"]
        index => "logstash-application-%{+YYYY.MM.dd}"
      }
    }

resources:
  requests:
    cpu: "500m"
    memory: "1Gi"
  limits:
    cpu: "1000m"
    memory: "2Gi"

service:
  type: ClusterIP
  ports:
    - name: beats
      port: 5044
      protocol: TCP
```

### Kibana Configuration
```yaml
# elk-stack/kibana/kibana-values.yaml
elasticsearchHosts: "http://elasticsearch:9200"

replicas: 1

resources:
  requests:
    cpu: "500m"
    memory: "1Gi"
  limits:
    cpu: "1000m"
    memory: "2Gi"

kibanaConfig:
  kibana.yml: |
    server.host: "0.0.0.0"
    elasticsearch.hosts: ["http://elasticsearch:9200"]
    xpack.monitoring.ui.container.elasticsearch.enabled: true

service:
  type: ClusterIP
  port: 5601

ingress:
  enabled: true
  className: nginx
  hosts:
    - host: kibana.taskmanagement.local
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: kibana-tls
      hosts:
        - kibana.taskmanagement.local
```

### Filebeat Configuration
```yaml
# elk-stack/filebeat/filebeat-values.yaml
daemonset:
  enabled: true

deployment:
  enabled: false

filebeatConfig:
  filebeat.yml: |
    filebeat.inputs:
    - type: container
      paths:
        - /var/log/containers/*task-management*.log
      processors:
        - add_kubernetes_metadata:
            host: ${NODE_NAME}
            matchers:
            - logs_path:
                logs_path: "/var/log/containers/"
    
    output.logstash:
      hosts: ["logstash:5044"]
    
    processors:
      - add_host_metadata:
          when.not.contains.tags: forwarded
      - add_cloud_metadata: ~
      - add_docker_metadata: ~
      - add_kubernetes_metadata: ~

resources:
  requests:
    cpu: "100m"
    memory: "100Mi"
  limits:
    cpu: "200m"
    memory: "200Mi"

extraVolumes:
  - name: varlibdockercontainers
    hostPath:
      path: /var/lib/docker/containers
  - name: varlog
    hostPath:
      path: /var/log

extraVolumeMounts:
  - name: varlibdockercontainers
    mountPath: /var/lib/docker/containers
    readOnly: true
  - name: varlog
    mountPath: /var/log
    readOnly: true
```

## Jaeger Tracing

### Jaeger Configuration
```yaml
# jaeger/jaeger-values.yaml
provisionDataStore:
  cassandra: false
  elasticsearch: true

storage:
  type: elasticsearch
  elasticsearch:
    host: elasticsearch
    port: 9200

agent:
  enabled: true

collector:
  enabled: true
  service:
    type: ClusterIP

query:
  enabled: true
  service:
    type: ClusterIP
  ingress:
    enabled: true
    className: nginx
    hosts:
      - jaeger.taskmanagement.local
    tls:
      - secretName: jaeger-tls
        hosts:
          - jaeger.taskmanagement.local

hotrod:
  enabled: false
```

## CloudWatch Integration

### CloudWatch Log Groups
```yaml
# cloudwatch/log-groups.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluent-bit-config
  namespace: amazon-cloudwatch
data:
  fluent-bit.conf: |
    [SERVICE]
        Flush                     5
        Grace                     30
        Log_Level                 info
        Daemon                    off
        Parsers_File              parsers.conf
        HTTP_Server               On
        HTTP_Listen               0.0.0.0
        HTTP_Port                 2020
        storage.path              /var/fluent-bit/state/flb-storage/
        storage.sync              normal
        storage.checksum          off
        storage.backlog.mem_limit 5M
    
    [INPUT]
        Name                tail
        Tag                 application.*
        Path                /var/log/containers/*task-management*.log
        Parser              docker
        DB                  /var/fluent-bit/state/flb_container.db
        Mem_Buf_Limit       50MB
        Skip_Long_Lines     On
        Refresh_Interval    10
    
    [FILTER]
        Name                kubernetes
        Match               application.*
        Kube_URL            https://kubernetes.default.svc:443
        Kube_CA_File        /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        Kube_Token_File     /var/run/secrets/kubernetes.io/serviceaccount/token
        Kube_Tag_Prefix     application.var.log.containers.
        Merge_Log           On
        Keep_Log            Off
        K8S-Logging.Parser  On
        K8S-Logging.Exclude On
    
    [OUTPUT]
        Name                cloudwatch_logs
        Match               application.*
        region              us-east-1
        log_group_name      /aws/containerinsights/task-management-cluster/application
        log_stream_prefix   task-management-
        auto_create_group   true
```

### CloudWatch Alarms
```yaml
# cloudwatch/alarms/application-alarms.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: cloudwatch-alarms
data:
  alarms.json: |
    {
      "alarms": [
        {
          "AlarmName": "TaskManagement-HighErrorRate",
          "AlarmDescription": "High error rate in Task Management API",
          "MetricName": "ErrorRate",
          "Namespace": "TaskManagement/Application",
          "Statistic": "Average",
          "Period": 300,
          "EvaluationPeriods": 2,
          "Threshold": 5.0,
          "ComparisonOperator": "GreaterThanThreshold",
          "AlarmActions": [
            "arn:aws:sns:us-east-1:123456789012:task-management-alerts"
          ]
        },
        {
          "AlarmName": "TaskManagement-HighResponseTime",
          "AlarmDescription": "High response time in Task Management API",
          "MetricName": "ResponseTime",
          "Namespace": "TaskManagement/Application",
          "Statistic": "Average",
          "Period": 300,
          "EvaluationPeriods": 2,
          "Threshold": 2000,
          "ComparisonOperator": "GreaterThanThreshold",
          "AlarmActions": [
            "arn:aws:sns:us-east-1:123456789012:task-management-alerts"
          ]
        }
      ]
    }
```

## Alert Configuration

### Slack Notifications
```yaml
# alerts/slack-webhook.yaml
apiVersion: v1
kind: Secret
metadata:
  name: alertmanager-slack-webhook
  namespace: monitoring
type: Opaque
stringData:
  webhook-url: "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: alertmanager-config
  namespace: monitoring
data:
  alertmanager.yml: |
    global:
      slack_api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'
    
    route:
      group_by: ['alertname', 'cluster', 'service']
      group_wait: 10s
      group_interval: 10s
      repeat_interval: 1h
      receiver: 'web.hook'
      routes:
      - match:
          severity: critical
        receiver: 'slack-critical'
      - match:
          severity: warning
        receiver: 'slack-warning'
    
    receivers:
    - name: 'web.hook'
      slack_configs:
      - channel: '#alerts'
        title: 'Task Management Alert'
        text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'
    
    - name: 'slack-critical'
      slack_configs:
      - channel: '#critical-alerts'
        title: '🚨 CRITICAL: {{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'
        color: 'danger'
    
    - name: 'slack-warning'
      slack_configs:
      - channel: '#alerts'
        title: '⚠️ WARNING: {{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'
        color: 'warning'
```

## Deployment Scripts

### Deploy Monitoring Stack
```bash
#!/bin/bash
# scripts/deploy-monitoring.sh

set -e

NAMESPACE="monitoring"

echo "🚀 Deploying monitoring stack..."

# Create namespace
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Add Helm repositories
echo "📦 Adding Helm repositories..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add elastic https://helm.elastic.co
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
helm repo update

# Deploy Prometheus Stack
echo "📊 Deploying Prometheus and Grafana..."
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace $NAMESPACE \
  --values prometheus/helm-values/prometheus-values.yaml \
  --wait

# Deploy Elasticsearch
echo "🔍 Deploying Elasticsearch..."
helm upgrade --install elasticsearch elastic/elasticsearch \
  --namespace $NAMESPACE \
  --values elk-stack/elasticsearch/elasticsearch-values.yaml \
  --wait

# Deploy Logstash
echo "📝 Deploying Logstash..."
helm upgrade --install logstash elastic/logstash \
  --namespace $NAMESPACE \
  --values elk-stack/logstash/logstash-values.yaml \
  --wait

# Deploy Kibana
echo "📈 Deploying Kibana..."
helm upgrade --install kibana elastic/kibana \
  --namespace $NAMESPACE \
  --values elk-stack/kibana/kibana-values.yaml \
  --wait

# Deploy Filebeat
echo "📋 Deploying Filebeat..."
helm upgrade --install filebeat elastic/filebeat \
  --namespace $NAMESPACE \
  --values elk-stack/filebeat/filebeat-values.yaml \
  --wait

# Deploy Jaeger
echo "🔗 Deploying Jaeger..."
helm upgrade --install jaeger jaegertracing/jaeger \
  --namespace $NAMESPACE \
  --values jaeger/jaeger-values.yaml \
  --wait

# Apply monitoring rules and service monitors
echo "📋 Applying monitoring rules..."
kubectl apply -f prometheus/rules/ -n $NAMESPACE
kubectl apply -f prometheus/targets/ -n $NAMESPACE

# Apply alert configurations
echo "🚨 Configuring alerts..."
kubectl apply -f alerts/ -n $NAMESPACE

echo "✅ Monitoring stack deployed successfully!"

# Display access information
echo ""
echo "🌐 Access URLs:"
echo "Grafana: http://grafana.taskmanagement.local"
echo "Prometheus: http://prometheus.taskmanagement.local"
echo "Kibana: http://kibana.taskmanagement.local"
echo "Jaeger: http://jaeger.taskmanagement.local"
echo ""
echo "📊 Default credentials:"
echo "Grafana - admin:admin123"
```

### Setup Dashboards
```bash
#!/bin/bash
# scripts/setup-dashboards.sh

set -e

GRAFANA_URL="http://grafana.taskmanagement.local"
GRAFANA_USER="admin"
GRAFANA_PASS="admin123"

echo "📊 Setting up Grafana dashboards..."

# Wait for Grafana to be ready
echo "⏳ Waiting for Grafana to be ready..."
until curl -s -f "$GRAFANA_URL/api/health" > /dev/null; do
  echo "Waiting for Grafana..."
  sleep 5
done

# Import dashboards
for dashboard in grafana/dashboards/*.json; do
  echo "Importing $(basename $dashboard)..."
  curl -X POST \
    -H "Content-Type: application/json" \
    -u "$GRAFANA_USER:$GRAFANA_PASS" \
    -d @"$dashboard" \
    "$GRAFANA_URL/api/dashboards/db"
done

echo "✅ Dashboards imported successfully!"
```

### Test Alerts
```bash
#!/bin/bash
# scripts/test-alerts.sh

set -e

echo "🧪 Testing alert system..."

# Create a test pod that will trigger alerts
kubectl run alert-test --image=busybox --restart=Never -- /bin/sh -c "while true; do echo 'Test alert'; sleep 1; done"

# Scale down application to trigger alert
kubectl scale deployment task-management-api --replicas=0 -n task-management-dev

echo "⏳ Waiting for alerts to trigger (60 seconds)..."
sleep 60

# Check alert status
echo "📊 Current alerts:"
curl -s http://prometheus.taskmanagement.local/api/v1/alerts | jq '.data.alerts[] | select(.state=="firing") | {alertname: .labels.alertname, state: .state}'

# Cleanup
kubectl delete pod alert-test --ignore-not-found
kubectl scale deployment task-management-api --replicas=3 -n task-management-dev

echo "✅ Alert test completed!"
```

## Performance Monitoring

### Custom Metrics
```java
// Add to Spring Boot application
@Component
public class CustomMetrics {
    
    private final Counter taskCreatedCounter;
    private final Timer taskProcessingTimer;
    private final Gauge activeTasksGauge;
    
    public CustomMetrics(MeterRegistry meterRegistry) {
        this.taskCreatedCounter = Counter.builder("tasks_created_total")
            .description("Total number of tasks created")
            .register(meterRegistry);
            
        this.taskProcessingTimer = Timer.builder("task_processing_duration")
            .description("Time taken to process tasks")
            .register(meterRegistry);
            
        this.activeTasksGauge = Gauge.builder("active_tasks")
            .description("Number of active tasks")
            .register(meterRegistry, this, CustomMetrics::getActiveTaskCount);
    }
    
    public void incrementTaskCreated() {
        taskCreatedCounter.increment();
    }
    
    public Timer.Sample startTaskProcessing() {
        return Timer.start(taskProcessingTimer);
    }
    
    private double getActiveTaskCount() {
        // Implementation to get active task count
        return 0.0;
    }
}
```

## Troubleshooting Guide

### Common Issues

1. **Prometheus not scraping metrics**
   ```bash
   kubectl logs -f deployment/prometheus-server -n monitoring
   kubectl get servicemonitors -n monitoring
   ```

2. **Grafana dashboard not loading**
   ```bash
   kubectl logs -f deployment/grafana -n monitoring
   kubectl port-forward svc/grafana 3000:80 -n monitoring
   ```

3. **ELK stack issues**
   ```bash
   kubectl logs -f statefulset/elasticsearch-master -n monitoring
   kubectl logs -f deployment/logstash -n monitoring
   kubectl logs -f daemonset/filebeat -n monitoring
   ```

4. **High resource usage**
   ```bash
   kubectl top pods -n monitoring
   kubectl describe pod <pod-name> -n monitoring
   ```

## Cost Optimization

### Resource Limits
```yaml
# Optimized resource configuration
resources:
  requests:
    memory: "256Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "200m"
```

### Storage Optimization
```yaml
# Retention policies
retention: 15d
retentionSize: 10GB

# Compression
compression: true
```

## Security Best Practices

### Network Policies
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: monitoring-network-policy
  namespace: monitoring
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
  egress:
  - to: []
    ports:
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53
```

## Project Completion Summary

🎉 **Congratulations!** You have successfully completed the comprehensive DevOps Microservice Project covering:

### ✅ Completed Sections:
1. **Project Overview** - Architecture and technology stack
2. **Source Code** - Complete Spring Boot REST API
3. **CloudFormation Setup** - AWS infrastructure templates
4. **Containerization** - Docker and Docker Compose
5. **Local Build & Test** - Development workflows
6. **Kubernetes Deployment** - Production-ready K8s manifests
7. **CI/CD Pipeline** - GitHub Actions and ArgoCD GitOps
8. **Infrastructure as Code** - Complete Terraform automation
9. **Monitoring & Observability** - Full monitoring stack

### 🛠️ Technologies Mastered:
- **Backend**: Java 17, Spring Boot, MySQL
- **Containerization**: Docker, Docker Compose
- **Orchestration**: Kubernetes, Helm, Kustomize
- **CI/CD**: GitHub Actions, ArgoCD
- **Infrastructure**: Terraform, AWS (EKS, RDS, ECR, CloudWatch)
- **Monitoring**: Prometheus, Grafana, ELK Stack, Jaeger
- **Security**: RBAC, Network Policies, Secret Management

### 🎯 Key Achievements:
- Production-ready microservice architecture
- Complete automation from code to deployment
- Comprehensive monitoring and observability
- Security best practices implementation
- Cost optimization strategies
- Multi-environment deployment workflows

This project demonstrates enterprise-level DevOps practices and prepares you for senior DevOps engineer roles with hands-on experience in modern cloud-native technologies!

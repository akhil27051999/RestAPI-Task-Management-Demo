# 8-Monitoring Files

## prometheus/prometheus-config.yaml
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: monitoring
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
      evaluation_interval: 15s

    rule_files:
      - "alert_rules.yml"

    scrape_configs:
      - job_name: 'prometheus'
        static_configs:
          - targets: ['localhost:9090']

      - job_name: 'task-management-api'
        kubernetes_sd_configs:
          - role: endpoints
            namespaces:
              names:
                - task-management
                - task-management-dev
                - task-management-staging
        relabel_configs:
          - source_labels: [__meta_kubernetes_service_name]
            action: keep
            regex: task-management-service
          - source_labels: [__meta_kubernetes_endpoint_port_name]
            action: keep
            regex: http
        metrics_path: '/actuator/prometheus'
        scrape_interval: 30s

      - job_name: 'kubernetes-nodes'
        kubernetes_sd_configs:
          - role: node
        relabel_configs:
          - action: labelmap
            regex: __meta_kubernetes_node_label_(.+)

      - job_name: 'kubernetes-pods'
        kubernetes_sd_configs:
          - role: pod
        relabel_configs:
          - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
            action: keep
            regex: true
          - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
            action: replace
            target_label: __metrics_path__
            regex: (.+)

  alert_rules.yml: |
    groups:
      - name: task-management-alerts
        rules:
          - alert: HighErrorRate
            expr: rate(http_server_requests_seconds_count{status=~"5.."}[5m]) / rate(http_server_requests_seconds_count[5m]) > 0.05
            for: 5m
            labels:
              severity: warning
            annotations:
              summary: "High error rate detected"
              description: "Error rate is above 5% for {{ $labels.instance }}"

          - alert: HighResponseTime
            expr: histogram_quantile(0.95, rate(http_server_requests_seconds_bucket[5m])) > 2
            for: 5m
            labels:
              severity: warning
            annotations:
              summary: "High response time"
              description: "95th percentile response time is {{ $value }}s"

          - alert: ApplicationDown
            expr: up{job="task-management-api"} == 0
            for: 1m
            labels:
              severity: critical
            annotations:
              summary: "Application is down"
              description: "Task Management API is not responding"
```

## prometheus/prometheus-deployment.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
  namespace: monitoring
  labels:
    app: prometheus
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      containers:
      - name: prometheus
        image: prom/prometheus:latest
        ports:
        - containerPort: 9090
        volumeMounts:
        - name: config-volume
          mountPath: /etc/prometheus
        - name: storage-volume
          mountPath: /prometheus
        args:
          - '--config.file=/etc/prometheus/prometheus.yml'
          - '--storage.tsdb.path=/prometheus'
          - '--web.console.libraries=/etc/prometheus/console_libraries'
          - '--web.console.templates=/etc/prometheus/consoles'
          - '--storage.tsdb.retention.time=200h'
          - '--web.enable-lifecycle'
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
      volumes:
      - name: config-volume
        configMap:
          name: prometheus-config
      - name: storage-volume
        persistentVolumeClaim:
          claimName: prometheus-pvc
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: prometheus-pvc
  namespace: monitoring
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 50Gi
  storageClassName: gp2
```

## prometheus/prometheus-service.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  name: prometheus-service
  namespace: monitoring
  labels:
    app: prometheus
spec:
  selector:
    app: prometheus
  ports:
  - name: web
    port: 9090
    targetPort: 9090
  type: ClusterIP
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: prometheus-ingress
  namespace: monitoring
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: prometheus-auth
spec:
  rules:
  - host: prometheus.taskmanagement.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: prometheus-service
            port:
              number: 9090
```

## grafana/grafana-deployment.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana
  namespace: monitoring
  labels:
    app: grafana
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      containers:
      - name: grafana
        image: grafana/grafana:latest
        ports:
        - containerPort: 3000
        env:
        - name: GF_SECURITY_ADMIN_USER
          value: "admin"
        - name: GF_SECURITY_ADMIN_PASSWORD
          valueFrom:
            secretKeyRef:
              name: grafana-secret
              key: admin-password
        - name: GF_USERS_ALLOW_SIGN_UP
          value: "false"
        volumeMounts:
        - name: grafana-storage
          mountPath: /var/lib/grafana
        - name: grafana-datasources
          mountPath: /etc/grafana/provisioning/datasources
        - name: grafana-dashboards-config
          mountPath: /etc/grafana/provisioning/dashboards
        - name: grafana-dashboards
          mountPath: /var/lib/grafana/dashboards
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "200m"
      volumes:
      - name: grafana-storage
        persistentVolumeClaim:
          claimName: grafana-pvc
      - name: grafana-datasources
        configMap:
          name: grafana-datasources
      - name: grafana-dashboards-config
        configMap:
          name: grafana-dashboards-config
      - name: grafana-dashboards
        configMap:
          name: grafana-dashboards
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: grafana-pvc
  namespace: monitoring
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: gp2
---
apiVersion: v1
kind: Secret
metadata:
  name: grafana-secret
  namespace: monitoring
type: Opaque
data:
  admin-password: YWRtaW4xMjM=  # admin123
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-datasources
  namespace: monitoring
data:
  datasources.yaml: |
    apiVersion: 1
    datasources:
    - name: Prometheus
      type: prometheus
      url: http://prometheus-service:9090
      access: proxy
      isDefault: true
    - name: Loki
      type: loki
      url: http://loki-service:3100
      access: proxy
```

## grafana/grafana-service.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  name: grafana-service
  namespace: monitoring
  labels:
    app: grafana
spec:
  selector:
    app: grafana
  ports:
  - name: web
    port: 3000
    targetPort: 3000
  type: ClusterIP
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: grafana-ingress
  namespace: monitoring
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  rules:
  - host: grafana.taskmanagement.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: grafana-service
            port:
              number: 3000
```

## grafana/dashboards/application-dashboard.json
```json
{
  "dashboard": {
    "id": null,
    "title": "Task Management API Dashboard",
    "tags": ["task-management", "spring-boot"],
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
            "unit": "reqps",
            "color": {"mode": "palette-classic"}
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
          "defaults": {"unit": "s"}
        },
        "gridPos": {"h": 8, "w": 6, "x": 12, "y": 0}
      },
      {
        "id": 4,
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
          "defaults": {"unit": "bytes"}
        },
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 8}
      }
    ],
    "time": {"from": "now-1h", "to": "now"},
    "refresh": "30s"
  }
}
```

## loki/loki-config.yaml
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: loki-config
  namespace: monitoring
data:
  loki.yaml: |
    auth_enabled: false

    server:
      http_listen_port: 3100

    ingester:
      lifecycler:
        address: 127.0.0.1
        ring:
          kvstore:
            store: inmemory
          replication_factor: 1
        final_sleep: 0s
      chunk_idle_period: 5m
      chunk_retain_period: 30s

    schema_config:
      configs:
        - from: 2020-10-24
          store: boltdb
          object_store: filesystem
          schema: v11
          index:
            prefix: index_
            period: 168h

    storage_config:
      boltdb:
        directory: /loki/index
      filesystem:
        directory: /loki/chunks

    limits_config:
      enforce_metric_name: false
      reject_old_samples: true
      reject_old_samples_max_age: 168h

    chunk_store_config:
      max_look_back_period: 0s

    table_manager:
      retention_deletes_enabled: false
      retention_period: 0s
```

## loki/loki-deployment.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: loki
  namespace: monitoring
  labels:
    app: loki
spec:
  replicas: 1
  selector:
    matchLabels:
      app: loki
  template:
    metadata:
      labels:
        app: loki
    spec:
      containers:
      - name: loki
        image: grafana/loki:latest
        ports:
        - containerPort: 3100
        volumeMounts:
        - name: config-volume
          mountPath: /etc/loki
        - name: storage-volume
          mountPath: /loki
        args:
          - -config.file=/etc/loki/loki.yaml
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "200m"
      volumes:
      - name: config-volume
        configMap:
          name: loki-config
      - name: storage-volume
        persistentVolumeClaim:
          claimName: loki-pvc
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: loki-pvc
  namespace: monitoring
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
  storageClassName: gp2
---
apiVersion: v1
kind: Service
metadata:
  name: loki-service
  namespace: monitoring
  labels:
    app: loki
spec:
  selector:
    app: loki
  ports:
  - name: http
    port: 3100
    targetPort: 3100
  type: ClusterIP
```

## elk-stack/elasticsearch.yaml
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: elasticsearch
  namespace: monitoring
spec:
  serviceName: elasticsearch
  replicas: 1
  selector:
    matchLabels:
      app: elasticsearch
  template:
    metadata:
      labels:
        app: elasticsearch
    spec:
      containers:
      - name: elasticsearch
        image: docker.elastic.co/elasticsearch/elasticsearch:8.8.0
        ports:
        - containerPort: 9200
        - containerPort: 9300
        env:
        - name: discovery.type
          value: single-node
        - name: ES_JAVA_OPTS
          value: "-Xms512m -Xmx512m"
        - name: xpack.security.enabled
          value: "false"
        volumeMounts:
        - name: elasticsearch-data
          mountPath: /usr/share/elasticsearch/data
        resources:
          requests:
            memory: "1Gi"
            cpu: "500m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
  volumeClaimTemplates:
  - metadata:
      name: elasticsearch-data
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: gp2
      resources:
        requests:
          storage: 50Gi
---
apiVersion: v1
kind: Service
metadata:
  name: elasticsearch
  namespace: monitoring
spec:
  selector:
    app: elasticsearch
  ports:
  - name: http
    port: 9200
    targetPort: 9200
  - name: transport
    port: 9300
    targetPort: 9300
  type: ClusterIP
```

## elk-stack/logstash.yaml
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: logstash-config
  namespace: monitoring
data:
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
    }
    
    output {
      elasticsearch {
        hosts => ["elasticsearch:9200"]
        index => "logstash-application-%{+YYYY.MM.dd}"
      }
    }
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: logstash
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: logstash
  template:
    metadata:
      labels:
        app: logstash
    spec:
      containers:
      - name: logstash
        image: docker.elastic.co/logstash/logstash:8.8.0
        ports:
        - containerPort: 5044
        volumeMounts:
        - name: config-volume
          mountPath: /usr/share/logstash/pipeline
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
      volumes:
      - name: config-volume
        configMap:
          name: logstash-config
---
apiVersion: v1
kind: Service
metadata:
  name: logstash
  namespace: monitoring
spec:
  selector:
    app: logstash
  ports:
  - name: beats
    port: 5044
    targetPort: 5044
  type: ClusterIP
```

## elk-stack/kibana.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kibana
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kibana
  template:
    metadata:
      labels:
        app: kibana
    spec:
      containers:
      - name: kibana
        image: docker.elastic.co/kibana/kibana:8.8.0
        ports:
        - containerPort: 5601
        env:
        - name: ELASTICSEARCH_HOSTS
          value: "http://elasticsearch:9200"
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: kibana
  namespace: monitoring
spec:
  selector:
    app: kibana
  ports:
  - name: http
    port: 5601
    targetPort: 5601
  type: ClusterIP
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: kibana-ingress
  namespace: monitoring
  annotations:
    kubernetes.io/ingress.class: "nginx"
spec:
  rules:
  - host: kibana.taskmanagement.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: kibana
            port:
              number: 5601
```

## load-testing/locust/locustfile.py
```python
from locust import HttpUser, task, between
import json
import random

class TaskManagementUser(HttpUser):
    wait_time = between(1, 3)
    
    def on_start(self):
        """Called when a user starts"""
        self.task_ids = []
    
    @task(3)
    def get_all_tasks(self):
        """Get all tasks - most common operation"""
        response = self.client.get("/api/tasks")
        if response.status_code == 200:
            tasks = response.json()
            if tasks:
                # Store task IDs for other operations
                self.task_ids = [task['id'] for task in tasks if 'id' in task]
    
    @task(2)
    def create_task(self):
        """Create a new task"""
        task_data = {
            "title": f"Load Test Task {random.randint(1, 1000)}",
            "description": f"This is a load test task created at {random.randint(1, 1000)}",
            "status": random.choice(["PENDING", "IN_PROGRESS", "COMPLETED"])
        }
        
        response = self.client.post(
            "/api/tasks",
            json=task_data,
            headers={"Content-Type": "application/json"}
        )
        
        if response.status_code == 201:
            task = response.json()
            if 'id' in task:
                self.task_ids.append(task['id'])
    
    @task(2)
    def get_task_by_id(self):
        """Get a specific task by ID"""
        if self.task_ids:
            task_id = random.choice(self.task_ids)
            self.client.get(f"/api/tasks/{task_id}")
    
    @task(1)
    def update_task(self):
        """Update an existing task"""
        if self.task_ids:
            task_id = random.choice(self.task_ids)
            update_data = {
                "title": f"Updated Task {random.randint(1, 1000)}",
                "description": "Updated during load test",
                "status": random.choice(["IN_PROGRESS", "COMPLETED"])
            }
            
            self.client.put(
                f"/api/tasks/{task_id}",
                json=update_data,
                headers={"Content-Type": "application/json"}
            )
    
    @task(1)
    def delete_task(self):
        """Delete a task"""
        if len(self.task_ids) > 5:  # Keep some tasks for other operations
            task_id = self.task_ids.pop()
            self.client.delete(f"/api/tasks/{task_id}")
    
    @task(1)
    def health_check(self):
        """Check application health"""
        self.client.get("/actuator/health")
    
    @task(1)
    def metrics_check(self):
        """Check metrics endpoint"""
        self.client.get("/actuator/prometheus")
```

## load-testing/locust/locust-deployment.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: locust-master
  namespace: monitoring
  labels:
    app: locust
    role: master
spec:
  replicas: 1
  selector:
    matchLabels:
      app: locust
      role: master
  template:
    metadata:
      labels:
        app: locust
        role: master
    spec:
      containers:
      - name: locust
        image: locustio/locust:latest
        ports:
        - containerPort: 8089
        - containerPort: 5557
        env:
        - name: LOCUST_MODE
          value: "master"
        - name: TARGET_HOST
          value: "http://task-management-service.task-management.svc.cluster.local"
        volumeMounts:
        - name: locust-scripts
          mountPath: /mnt/locust
        command: ["locust"]
        args: ["--master", "-f", "/mnt/locust/locustfile.py"]
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "200m"
      volumes:
      - name: locust-scripts
        configMap:
          name: locust-scripts
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: locust-worker
  namespace: monitoring
  labels:
    app: locust
    role: worker
spec:
  replicas: 2
  selector:
    matchLabels:
      app: locust
      role: worker
  template:
    metadata:
      labels:
        app: locust
        role: worker
    spec:
      containers:
      - name: locust
        image: locustio/locust:latest
        env:
        - name: LOCUST_MODE
          value: "worker"
        - name: LOCUST_MASTER
          value: "locust-master-service"
        - name: TARGET_HOST
          value: "http://task-management-service.task-management.svc.cluster.local"
        volumeMounts:
        - name: locust-scripts
          mountPath: /mnt/locust
        command: ["locust"]
        args: ["--worker", "--master-host=locust-master-service", "-f", "/mnt/locust/locustfile.py"]
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "200m"
      volumes:
      - name: locust-scripts
        configMap:
          name: locust-scripts
---
apiVersion: v1
kind: Service
metadata:
  name: locust-master-service
  namespace: monitoring
spec:
  selector:
    app: locust
    role: master
  ports:
  - name: web
    port: 8089
    targetPort: 8089
  - name: master
    port: 5557
    targetPort: 5557
  type: ClusterIP
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: locust-ingress
  namespace: monitoring
  annotations:
    kubernetes.io/ingress.class: "nginx"
spec:
  rules:
  - host: locust.taskmanagement.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: locust-master-service
            port:
              number: 8089
```

## load-testing/k6/load-test.js
```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');

// Test configuration
export const options = {
  stages: [
    { duration: '2m', target: 10 }, // Ramp up to 10 users
    { duration: '5m', target: 10 }, // Stay at 10 users
    { duration: '2m', target: 20 }, // Ramp up to 20 users
    { duration: '5m', target: 20 }, // Stay at 20 users
    { duration: '2m', target: 0 },  // Ramp down to 0 users
  ],
  thresholds: {
    http_req_duration: ['p(95)<2000'], // 95% of requests must complete below 2s
    http_req_failed: ['rate<0.05'],    // Error rate must be below 5%
    errors: ['rate<0.05'],             // Custom error rate
  },
};

const BASE_URL = __ENV.TARGET_HOST || 'http://localhost:8080';

// Test data
const taskTitles = [
  'Complete project documentation',
  'Review code changes',
  'Deploy to production',
  'Update dependencies',
  'Fix critical bug',
  'Implement new feature',
  'Write unit tests',
  'Performance optimization'
];

const taskStatuses = ['PENDING', 'IN_PROGRESS', 'COMPLETED'];

let createdTaskIds = [];

export default function () {
  // Test scenarios with different weights
  const scenario = Math.random();
  
  if (scenario < 0.4) {
    // 40% - Get all tasks
    getAllTasks();
  } else if (scenario < 0.6) {
    // 20% - Create task
    createTask();
  } else if (scenario < 0.8) {
    // 20% - Get task by ID
    getTaskById();
  } else if (scenario < 0.9) {
    // 10% - Update task
    updateTask();
  } else {
    // 10% - Delete task
    deleteTask();
  }
  
  // Health check occasionally
  if (Math.random() < 0.1) {
    healthCheck();
  }
  
  sleep(1);
}

function getAllTasks() {
  const response = http.get(`${BASE_URL}/api/tasks`);
  
  const success = check(response, {
    'GET /api/tasks status is 200': (r) => r.status === 200,
    'GET /api/tasks response time < 1000ms': (r) => r.timings.duration < 1000,
  });
  
  errorRate.add(!success);
  
  if (success && response.json()) {
    const tasks = response.json();
    if (Array.isArray(tasks) && tasks.length > 0) {
      // Store some task IDs for other operations
      createdTaskIds = tasks.slice(0, 10).map(task => task.id).filter(id => id);
    }
  }
}

function createTask() {
  const taskData = {
    title: taskTitles[Math.floor(Math.random() * taskTitles.length)],
    description: `Load test task created at ${new Date().toISOString()}`,
    status: taskStatuses[Math.floor(Math.random() * taskStatuses.length)]
  };
  
  const response = http.post(`${BASE_URL}/api/tasks`, JSON.stringify(taskData), {
    headers: { 'Content-Type': 'application/json' },
  });
  
  const success = check(response, {
    'POST /api/tasks status is 201': (r) => r.status === 201,
    'POST /api/tasks response time < 2000ms': (r) => r.timings.duration < 2000,
    'POST /api/tasks returns task with ID': (r) => {
      try {
        const task = r.json();
        return task && task.id;
      } catch (e) {
        return false;
      }
    },
  });
  
  errorRate.add(!success);
  
  if (success && response.json() && response.json().id) {
    createdTaskIds.push(response.json().id);
    // Keep only last 20 task IDs to prevent memory issues
    if (createdTaskIds.length > 20) {
      createdTaskIds = createdTaskIds.slice(-20);
    }
  }
}

function getTaskById() {
  if (createdTaskIds.length === 0) {
    return;
  }
  
  const taskId = createdTaskIds[Math.floor(Math.random() * createdTaskIds.length)];
  const response = http.get(`${BASE_URL}/api/tasks/${taskId}`);
  
  const success = check(response, {
    'GET /api/tasks/{id} status is 200 or 404': (r) => r.status === 200 || r.status === 404,
    'GET /api/tasks/{id} response time < 1000ms': (r) => r.timings.duration < 1000,
  });
  
  errorRate.add(!success);
}

function updateTask() {
  if (createdTaskIds.length === 0) {
    return;
  }
  
  const taskId = createdTaskIds[Math.floor(Math.random() * createdTaskIds.length)];
  const updateData = {
    title: `Updated: ${taskTitles[Math.floor(Math.random() * taskTitles.length)]}`,
    description: `Updated during load test at ${new Date().toISOString()}`,
    status: taskStatuses[Math.floor(Math.random() * taskStatuses.length)]
  };
  
  const response = http.put(`${BASE_URL}/api/tasks/${taskId}`, JSON.stringify(updateData), {
    headers: { 'Content-Type': 'application/json' },
  });
  
  const success = check(response, {
    'PUT /api/tasks/{id} status is 200 or 404': (r) => r.status === 200 || r.status === 404,
    'PUT /api/tasks/{id} response time < 2000ms': (r) => r.timings.duration < 2000,
  });
  
  errorRate.add(!success);
}

function deleteTask() {
  if (createdTaskIds.length <= 5) {
    return; // Keep some tasks for other operations
  }
  
  const taskId = createdTaskIds.pop();
  const response = http.del(`${BASE_URL}/api/tasks/${taskId}`);
  
  const success = check(response, {
    'DELETE /api/tasks/{id} status is 204 or 404': (r) => r.status === 204 || r.status === 404,
    'DELETE /api/tasks/{id} response time < 1000ms': (r) => r.timings.duration < 1000,
  });
  
  errorRate.add(!success);
}

function healthCheck() {
  const response = http.get(`${BASE_URL}/actuator/health`);
  
  const success = check(response, {
    'Health check status is 200': (r) => r.status === 200,
    'Health check response time < 500ms': (r) => r.timings.duration < 500,
    'Health check status is UP': (r) => {
      try {
        const health = r.json();
        return health && health.status === 'UP';
      } catch (e) {
        return false;
      }
    },
  });
  
  errorRate.add(!success);
}
```

## README.md
```markdown
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
```

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

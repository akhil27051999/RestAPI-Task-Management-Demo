# Monitoring Stack

## Prometheus

### prometheus-deployment.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
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
        - name: prometheus-config
          mountPath: /etc/prometheus
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
      volumes:
      - name: prometheus-config
        configMap:
          name: prometheus-config
```

### prometheus-service.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  name: prometheus-service
spec:
  selector:
    app: prometheus
  ports:
    - port: 9090
      targetPort: 9090
  type: LoadBalancer
```

## Grafana

### grafana-deployment.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana
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
        - name: GF_SECURITY_ADMIN_PASSWORD
          value: "admin123"
        volumeMounts:
        - name: grafana-storage
          mountPath: /var/lib/grafana
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
```

### grafana-service.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  name: grafana-service
spec:
  selector:
    app: grafana
  ports:
    - port: 3000
      targetPort: 3000
  type: LoadBalancer
```

### dashboards/frontend-dashboard.json
```json
{
  "dashboard": {
    "id": null,
    "title": "Frontend Dashboard",
    "tags": ["frontend", "nginx"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "HTTP Requests",
        "type": "stat",
        "targets": [
          {
            "expr": "rate(nginx_http_requests_total[5m])",
            "legendFormat": "Requests/sec"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0}
      },
      {
        "id": 2,
        "title": "Response Time",
        "type": "graph",
        "targets": [
          {
            "expr": "nginx_http_request_duration_seconds",
            "legendFormat": "Response Time"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0}
      }
    ],
    "time": {"from": "now-1h", "to": "now"},
    "refresh": "5s"
  }
}
```

## Loki

### loki-config.yaml
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: loki-config
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
    schema_config:
      configs:
        - from: 2020-10-24
          store: boltdb-shipper
          object_store: filesystem
          schema: v11
          index:
            prefix: index_
            period: 24h
    storage_config:
      boltdb_shipper:
        active_index_directory: /loki/boltdb-shipper-active
        cache_location: /loki/boltdb-shipper-cache
      filesystem:
        directory: /loki/chunks
```

### loki-deployment.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: loki
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
        - name: loki-config
          mountPath: /etc/loki
        - name: loki-storage
          mountPath: /loki
      volumes:
      - name: loki-config
        configMap:
          name: loki-config
      - name: loki-storage
        emptyDir: {}
```

## ELK Stack

### elasticsearch.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: elasticsearch
spec:
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
        env:
        - name: discovery.type
          value: single-node
        - name: xpack.security.enabled
          value: "false"
        resources:
          requests:
            memory: "1Gi"
          limits:
            memory: "2Gi"
---
apiVersion: v1
kind: Service
metadata:
  name: elasticsearch-service
spec:
  selector:
    app: elasticsearch
  ports:
    - port: 9200
      targetPort: 9200
```

### logstash.yaml
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: logstash-config
data:
  logstash.conf: |
    input {
      beats {
        port => 5044
      }
    }
    filter {
      if [fields][service] == "frontend" {
        grok {
          match => { "message" => "%{NGINXACCESS}" }
        }
      }
    }
    output {
      elasticsearch {
        hosts => ["elasticsearch-service:9200"]
        index => "logs-%{+YYYY.MM.dd}"
      }
    }
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: logstash
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
        - name: logstash-config
          mountPath: /usr/share/logstash/pipeline
      volumes:
      - name: logstash-config
        configMap:
          name: logstash-config
```

### kibana.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kibana
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
          value: "http://elasticsearch-service:9200"
---
apiVersion: v1
kind: Service
metadata:
  name: kibana-service
spec:
  selector:
    app: kibana
  ports:
    - port: 5601
      targetPort: 5601
  type: LoadBalancer
```

## Load Testing

### locust/locustfile.py
```python
from locust import HttpUser, task, between

class TaskManagementUser(HttpUser):
    wait_time = between(1, 3)
    
    def on_start(self):
        # Login or setup if needed
        pass
    
    @task(3)
    def view_dashboard(self):
        self.client.get("/")
    
    @task(2)
    def get_tasks(self):
        self.client.get("/api/tasks")
    
    @task(1)
    def create_task(self):
        self.client.post("/api/tasks", json={
            "title": "Load Test Task",
            "description": "Created by load test",
            "priority": "MEDIUM",
            "completed": False
        })
    
    @task(1)
    def update_task(self):
        # Get a task first, then update
        response = self.client.get("/api/tasks")
        if response.status_code == 200:
            tasks = response.json()
            if tasks:
                task_id = tasks[0]["id"]
                self.client.put(f"/api/tasks/{task_id}", json={
                    "completed": True
                })
```

### locust/locust-deployment.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: locust-master
spec:
  replicas: 1
  selector:
    matchLabels:
      app: locust-master
  template:
    metadata:
      labels:
        app: locust-master
    spec:
      containers:
      - name: locust
        image: locustio/locust
        ports:
        - containerPort: 8089
        command: ["locust"]
        args: ["--master", "--host=http://task-frontend-service"]
        volumeMounts:
        - name: locust-scripts
          mountPath: /mnt/locust
      volumes:
      - name: locust-scripts
        configMap:
          name: locust-scripts
---
apiVersion: v1
kind: Service
metadata:
  name: locust-service
spec:
  selector:
    app: locust-master
  ports:
    - port: 8089
      targetPort: 8089
  type: LoadBalancer
```

### k6/load-test.js
```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
  stages: [
    { duration: '2m', target: 10 },
    { duration: '5m', target: 10 },
    { duration: '2m', target: 20 },
    { duration: '5m', target: 20 },
    { duration: '2m', target: 0 },
  ],
};

export default function() {
  // Test frontend
  let frontendResponse = http.get('http://task-frontend-service/');
  check(frontendResponse, {
    'frontend status is 200': (r) => r.status === 200,
    'frontend response time < 500ms': (r) => r.timings.duration < 500,
  });

  // Test API
  let apiResponse = http.get('http://task-frontend-service/api/tasks');
  check(apiResponse, {
    'api status is 200': (r) => r.status === 200,
    'api response time < 1000ms': (r) => r.timings.duration < 1000,
  });

  // Create task
  let createResponse = http.post('http://task-frontend-service/api/tasks', 
    JSON.stringify({
      title: 'K6 Test Task',
      description: 'Created by K6 load test',
      priority: 'LOW',
      completed: false
    }), 
    { headers: { 'Content-Type': 'application/json' } }
  );
  
  check(createResponse, {
    'create task status is 201': (r) => r.status === 201,
  });

  sleep(1);
}
```

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

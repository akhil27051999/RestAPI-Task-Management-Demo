# Best Practices Guide

## Development Best Practices

### Code Quality

#### Code Structure
- Follow layered architecture (Controller → Service → Repository)
- Use dependency injection with Spring annotations
- Implement proper error handling with custom exceptions
- Write comprehensive unit and integration tests
- Maintain test coverage above 80%

#### API Design
```java
// Good: RESTful endpoint design
@GetMapping("/api/tasks/{id}")
public ResponseEntity<TaskDTO> getTask(@PathVariable Long id) {
    return ResponseEntity.ok(taskService.getTaskById(id));
}

// Good: Proper HTTP status codes
@PostMapping("/api/tasks")
public ResponseEntity<TaskDTO> createTask(@Valid @RequestBody CreateTaskRequest request) {
    TaskDTO created = taskService.createTask(request);
    return ResponseEntity.status(HttpStatus.CREATED).body(created);
}
```

#### Error Handling
```java
// Good: Global exception handler
@RestControllerAdvice
public class GlobalExceptionHandler {
    
    @ExceptionHandler(TaskNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleTaskNotFound(TaskNotFoundException ex) {
        ErrorResponse error = ErrorResponse.builder()
                .timestamp(LocalDateTime.now())
                .status(HttpStatus.NOT_FOUND.value())
                .error("Not Found")
                .message(ex.getMessage())
                .build();
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
    }
}
```

#### Validation
```java
// Good: Input validation
public class CreateTaskRequest {
    @NotBlank(message = "Title is required")
    @Size(max = 255, message = "Title must not exceed 255 characters")
    private String title;
    
    @Size(max = 1000, message = "Description must not exceed 1000 characters")
    private String description;
}
```

### Database Best Practices

#### Entity Design
```java
// Good: Proper entity annotations
@Entity
@Table(name = "tasks", indexes = {
    @Index(name = "idx_status", columnList = "status"),
    @Index(name = "idx_created_at", columnList = "created_at")
})
public class Task {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
    
    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
```

#### Repository Patterns
```java
// Good: Custom query methods
@Repository
public interface TaskRepository extends JpaRepository<Task, Long> {
    
    @Query("SELECT t FROM Task t WHERE t.status = :status AND t.createdAt >= :since")
    List<Task> findRecentTasksByStatus(@Param("status") TaskStatus status, 
                                      @Param("since") LocalDateTime since);
    
    @Modifying
    @Query("UPDATE Task t SET t.status = :newStatus WHERE t.status = :oldStatus")
    int bulkUpdateStatus(@Param("oldStatus") TaskStatus oldStatus, 
                        @Param("newStatus") TaskStatus newStatus);
}
```

#### Connection Pool Configuration
```yaml
# Good: HikariCP configuration
spring:
  datasource:
    hikari:
      maximum-pool-size: 20
      minimum-idle: 5
      connection-timeout: 30000
      idle-timeout: 600000
      max-lifetime: 1800000
      leak-detection-threshold: 60000
```

### Security Best Practices

#### Input Validation
```java
// Good: Comprehensive validation
@PostMapping("/api/tasks")
public ResponseEntity<TaskDTO> createTask(@Valid @RequestBody CreateTaskRequest request) {
    // Validation is handled by @Valid annotation
    TaskDTO created = taskService.createTask(request);
    return ResponseEntity.status(HttpStatus.CREATED).body(created);
}
```

#### SQL Injection Prevention
```java
// Good: Use parameterized queries
@Query("SELECT t FROM Task t WHERE t.title LIKE %:keyword%")
List<Task> searchByTitle(@Param("keyword") String keyword);

// Bad: String concatenation (vulnerable to SQL injection)
// "SELECT * FROM tasks WHERE title LIKE '%" + keyword + "%'"
```

#### Secrets Management
```yaml
# Good: Use environment variables
spring:
  datasource:
    username: ${DB_USERNAME}
    password: ${DB_PASSWORD}

# Bad: Hardcoded credentials
# username: admin
# password: password123
```

## Containerization Best Practices

### Dockerfile Optimization

#### Multi-stage Build
```dockerfile
# Good: Multi-stage build
FROM openjdk:17-jdk-slim as builder
WORKDIR /app
COPY . .
RUN ./mvnw clean package -DskipTests

FROM openjdk:17-jre-slim
COPY --from=builder /app/target/app.jar app.jar
ENTRYPOINT ["java", "-jar", "app.jar"]
```

#### Security Hardening
```dockerfile
# Good: Non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser
USER appuser

# Good: Health checks
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1
```

#### Resource Optimization
```dockerfile
# Good: JVM optimization for containers
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -XX:+UseG1GC"
```

### Docker Compose Best Practices

#### Service Dependencies
```yaml
# Good: Health check dependencies
services:
  app:
    depends_on:
      mysql:
        condition: service_healthy
  
  mysql:
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 30s
      timeout: 10s
      retries: 3
```

#### Resource Limits
```yaml
# Good: Resource constraints
services:
  app:
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '0.5'
        reservations:
          memory: 512M
          cpus: '0.25'
```

## Kubernetes Best Practices

### Resource Management

#### Resource Requests and Limits
```yaml
# Good: Proper resource configuration
resources:
  requests:
    memory: "512Mi"
    cpu: "250m"
  limits:
    memory: "1Gi"
    cpu: "500m"
```

#### Horizontal Pod Autoscaler
```yaml
# Good: HPA configuration
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: task-api-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: task-api
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

### Security Best Practices

#### Pod Security Context
```yaml
# Good: Security context
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000
  capabilities:
    drop:
    - ALL
  readOnlyRootFilesystem: true
```

#### Network Policies
```yaml
# Good: Network policy
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: task-api-netpol
spec:
  podSelector:
    matchLabels:
      app: task-api
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: nginx-ingress
    ports:
    - protocol: TCP
      port: 8080
```

#### Secret Management
```yaml
# Good: Use secrets for sensitive data
env:
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: task-api-secret
      key: mysql-password
```

### High Availability

#### Pod Disruption Budget
```yaml
# Good: PDB configuration
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: task-api-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: task-api
```

#### Anti-Affinity Rules
```yaml
# Good: Pod anti-affinity
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        labelSelector:
          matchExpressions:
          - key: app
            operator: In
            values:
            - task-api
        topologyKey: kubernetes.io/hostname
```

### Health Checks

#### Comprehensive Probes
```yaml
# Good: All three probe types
livenessProbe:
  httpGet:
    path: /actuator/health
    port: 8080
  initialDelaySeconds: 60
  periodSeconds: 30

readinessProbe:
  httpGet:
    path: /actuator/health/readiness
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10

startupProbe:
  httpGet:
    path: /actuator/health
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10
  failureThreshold: 12
```

## CI/CD Best Practices

### Pipeline Design

#### Stage Separation
```yaml
# Good: Clear stage separation
jobs:
  test:
    name: Test
    runs-on: ubuntu-latest
    steps:
      - name: Run Tests
        run: mvn test

  security:
    name: Security Scan
    needs: test
    steps:
      - name: OWASP Scan
        run: mvn dependency-check:check

  build:
    name: Build & Push
    needs: [test, security]
    steps:
      - name: Build Image
        run: docker build -t app:${{ github.sha }} .
```

#### Environment Promotion
```yaml
# Good: Environment-specific deployments
deploy-dev:
  if: github.ref == 'refs/heads/develop'
  environment: development

deploy-prod:
  if: github.ref == 'refs/heads/main'
  environment: production
  needs: [deploy-staging]
```

### GitOps Best Practices

#### Repository Structure
```
gitops-repo/
├── environments/
│   ├── dev/
│   │   ├── kustomization.yaml
│   │   └── values.yaml
│   ├── staging/
│   └── prod/
└── base/
    ├── deployment.yaml
    ├── service.yaml
    └── kustomization.yaml
```

#### ArgoCD Configuration
```yaml
# Good: ArgoCD application
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: task-management-api
spec:
  project: default
  source:
    repoURL: https://github.com/org/gitops-repo.git
    targetRevision: HEAD
    path: environments/prod
  destination:
    server: https://kubernetes.default.svc
    namespace: task-management
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

## Monitoring Best Practices

### Metrics Collection

#### Application Metrics
```java
// Good: Custom metrics
@Component
public class TaskMetrics {
    private final Counter taskCreatedCounter;
    private final Timer taskProcessingTimer;
    
    public TaskMetrics(MeterRegistry meterRegistry) {
        this.taskCreatedCounter = Counter.builder("tasks.created.total")
            .description("Total number of tasks created")
            .register(meterRegistry);
            
        this.taskProcessingTimer = Timer.builder("task.processing.duration")
            .description("Time taken to process tasks")
            .register(meterRegistry);
    }
}
```

#### Prometheus Configuration
```yaml
# Good: Comprehensive scrape config
scrape_configs:
  - job_name: 'task-management-api'
    kubernetes_sd_configs:
      - role: endpoints
    relabel_configs:
      - source_labels: [__meta_kubernetes_service_name]
        action: keep
        regex: task-management-service
    metrics_path: '/actuator/prometheus'
    scrape_interval: 30s
```

### Alerting Rules

#### Meaningful Alerts
```yaml
# Good: Actionable alerts
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
          description: "Error rate is {{ $value | humanizePercentage }} for {{ $labels.instance }}"
          runbook_url: "https://wiki.company.com/runbooks/high-error-rate"
```

### Logging Best Practices

#### Structured Logging
```java
// Good: Structured logging
@Slf4j
public class TaskService {
    public TaskDTO createTask(CreateTaskRequest request) {
        log.info("Creating task with title: {}", request.getTitle());
        
        try {
            Task task = taskMapper.toEntity(request);
            Task saved = taskRepository.save(task);
            
            log.info("Task created successfully with id: {}", saved.getId());
            return taskMapper.toDTO(saved);
        } catch (Exception e) {
            log.error("Failed to create task with title: {}", request.getTitle(), e);
            throw new TaskCreationException("Failed to create task", e);
        }
    }
}
```

#### Log Levels
```yaml
# Good: Environment-specific log levels
logging:
  level:
    com.taskapi: INFO
    org.springframework.web: WARN
    org.hibernate.SQL: WARN
  pattern:
    console: "%d{yyyy-MM-dd HH:mm:ss} [%thread] %-5level %logger{36} - %msg%n"
```

## Performance Best Practices

### Database Optimization

#### Indexing Strategy
```sql
-- Good: Strategic indexes
CREATE INDEX idx_status_created ON tasks(status, created_at);
CREATE INDEX idx_assigned_user ON tasks(assigned_to) WHERE assigned_to IS NOT NULL;
CREATE INDEX idx_due_date ON tasks(due_date) WHERE due_date IS NOT NULL;
```

#### Query Optimization
```java
// Good: Efficient queries
@Query("SELECT t FROM Task t WHERE t.status = :status AND t.createdAt >= :since ORDER BY t.createdAt DESC")
Page<Task> findRecentTasksByStatus(@Param("status") TaskStatus status, 
                                  @Param("since") LocalDateTime since, 
                                  Pageable pageable);
```

### Caching Strategy

#### Application-Level Caching
```java
// Good: Strategic caching
@Service
public class TaskService {
    
    @Cacheable(value = "tasks", key = "#id")
    public TaskDTO getTaskById(Long id) {
        return taskRepository.findById(id)
                .map(taskMapper::toDTO)
                .orElseThrow(() -> new TaskNotFoundException("Task not found"));
    }
    
    @CacheEvict(value = "tasks", key = "#id")
    public void deleteTask(Long id) {
        taskRepository.deleteById(id);
    }
}
```

### JVM Tuning

#### Container-Optimized Settings
```yaml
# Good: JVM optimization
env:
- name: JAVA_OPTS
  value: >-
    -XX:+UseContainerSupport
    -XX:MaxRAMPercentage=75.0
    -XX:+UseG1GC
    -XX:MaxGCPauseMillis=200
    -XX:+UnlockExperimentalVMOptions
    -XX:+UseCGroupMemoryLimitForHeap
```

## Disaster Recovery Best Practices

### Backup Strategy

#### Database Backups
```bash
# Good: Automated backup script
#!/bin/bash
BACKUP_DIR="/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="taskdb_backup_${DATE}.sql"

kubectl exec -it deployment/mysql -n task-management -- \
  mysqldump -u root -p${MYSQL_ROOT_PASSWORD} taskdb > ${BACKUP_DIR}/${BACKUP_FILE}

# Compress backup
gzip ${BACKUP_DIR}/${BACKUP_FILE}

# Upload to S3
aws s3 cp ${BACKUP_DIR}/${BACKUP_FILE}.gz s3://backups-bucket/database/
```

#### Configuration Backups
```bash
# Good: Kubernetes resource backup
kubectl get all,configmap,secret,pvc -n task-management -o yaml > k8s-backup-$(date +%Y%m%d).yaml
```

### Recovery Procedures

#### Database Recovery
```bash
# Good: Recovery script
#!/bin/bash
BACKUP_FILE=$1

# Stop application
kubectl scale deployment task-api --replicas=0 -n task-management

# Restore database
kubectl exec -i deployment/mysql -n task-management -- \
  mysql -u root -p${MYSQL_ROOT_PASSWORD} taskdb < ${BACKUP_FILE}

# Start application
kubectl scale deployment task-api --replicas=3 -n task-management

# Verify recovery
kubectl wait --for=condition=ready pod -l app=task-api -n task-management --timeout=300s
```

This best practices guide provides comprehensive guidelines for developing, deploying, and maintaining the Task Management API in production environments.
```

## Quick Reference

### Deploy Documentation
```bash
# Create documentation namespace
kubectl create namespace documentation

# Deploy as ConfigMaps for easy access
kubectl create configmap api-docs --from-file=api-documentation.md -n documentation
kubectl create configmap deployment-guide --from-file=deployment-guide.md -n documentation
kubectl create configmap troubleshooting --from-file=troubleshooting.md -n documentation
kubectl create configmap best-practices --from-file=best-practices.md -n documentation
```

### Access Documentation
```bash
# View documentation
kubectl get configmap api-docs -n documentation -o yaml
kubectl get configmap deployment-guide -n documentation -o yaml
kubectl get configmap troubleshooting -n documentation -o yaml
kubectl get configmap best-practices -n documentation -o yaml
```

## Common Issues and Solutions

### Application Issues

#### Application Won't Start

**Symptoms:**
- Pod in CrashLoopBackOff state
- Application logs show startup errors
- Health check endpoints not responding

**Diagnosis:**
```bash
# Check pod status
kubectl get pods -n task-management

# Check pod logs
kubectl logs -f deployment/task-api -n task-management

# Describe pod for events
kubectl describe pod <pod-name> -n task-management
```

**Common Causes & Solutions:**

1. **Database Connection Issues**
```bash
# Check database connectivity
kubectl exec -it deployment/task-api -n task-management -- nc -zv mysql-service 3306

# Verify database credentials
kubectl get secret task-api-secret -n task-management -o yaml
echo "dGFza3VzZXI=" | base64 -d  # Decode secret values
```

2. **Missing Environment Variables**
```bash
# Check environment variables
kubectl exec -it deployment/task-api -n task-management -- env | grep SPRING

# Update deployment with missing variables
kubectl patch deployment task-api -n task-management -p '{"spec":{"template":{"spec":{"containers":[{"name":"task-api","env":[{"name":"SPRING_PROFILES_ACTIVE","value":"prod"}]}]}}}}'
```

3. **Resource Constraints**
```bash
# Check resource usage
kubectl top pods -n task-management

# Increase resource limits
kubectl patch deployment task-api -n task-management -p '{"spec":{"template":{"spec":{"containers":[{"name":"task-api","resources":{"limits":{"memory":"2Gi","cpu":"1000m"}}}]}}}}'
```

#### High Memory Usage

**Symptoms:**
- Pods being OOMKilled
- High memory usage in monitoring
- Application becoming unresponsive

**Diagnosis:**
```bash
# Check memory usage
kubectl top pods -n task-management

# Check JVM memory
kubectl exec -it deployment/task-api -n task-management -- jstat -gc <pid>

# Check heap dump (if available)
kubectl exec -it deployment/task-api -n task-management -- jcmd <pid> GC.run_finalization
```

**Solutions:**
```bash
# Increase memory limits
kubectl patch deployment task-api -n task-management -p '{"spec":{"template":{"spec":{"containers":[{"name":"task-api","resources":{"limits":{"memory":"2Gi"}}}]}}}}'

# Optimize JVM settings
kubectl patch deployment task-api -n task-management -p '{"spec":{"template":{"spec":{"containers":[{"name":"task-api","env":[{"name":"JAVA_OPTS","value":"-XX:MaxRAMPercentage=70.0 -XX:+UseG1GC"}]}]}}}}'
```

#### Slow Response Times

**Symptoms:**
- API responses taking >2 seconds
- Timeout errors
- High CPU usage

**Diagnosis:**
```bash
# Check response times in Grafana
# URL: http://grafana.taskmanagement.local

# Check database performance
kubectl exec -it deployment/mysql -n task-management -- mysql -u root -p -e "SHOW PROCESSLIST;"

# Check application metrics
curl http://localhost:8080/actuator/metrics/http.server.requests
```

**Solutions:**
```bash
# Scale application horizontally
kubectl scale deployment task-api --replicas=5 -n task-management

# Add database indexes
kubectl exec -it deployment/mysql -n task-management -- mysql -u root -p taskdb -e "CREATE INDEX idx_status ON tasks(status);"

# Enable connection pooling
# Update application.yml with HikariCP settings
```

### Database Issues

#### Database Connection Refused

**Symptoms:**
- "Connection refused" errors in application logs
- Database health check failing
- Unable to connect to MySQL

**Diagnosis:**
```bash
# Check MySQL pod status
kubectl get pods -l app=mysql -n task-management

# Check MySQL logs
kubectl logs -f deployment/mysql -n task-management

# Test connection from application pod
kubectl exec -it deployment/task-api -n task-management -- nc -zv mysql-service 3306
```

**Solutions:**
```bash
# Restart MySQL pod
kubectl rollout restart deployment/mysql -n task-management

# Check service configuration
kubectl get svc mysql-service -n task-management -o yaml

# Verify network policies
kubectl get networkpolicy -n task-management
```

#### Database Performance Issues

**Symptoms:**
- Slow query execution
- High database CPU usage
- Connection pool exhaustion

**Diagnosis:**
```bash
# Check slow query log
kubectl exec -it deployment/mysql -n task-management -- mysql -u root -p -e "SHOW VARIABLES LIKE 'slow_query_log';"

# Check running processes
kubectl exec -it deployment/mysql -n task-management -- mysql -u root -p -e "SHOW PROCESSLIST;"

# Check database size
kubectl exec -it deployment/mysql -n task-management -- mysql -u root -p -e "SELECT table_schema, ROUND(SUM(data_length + index_length) / 1024 / 1024, 1) AS 'DB Size in MB' FROM information_schema.tables GROUP BY table_schema;"
```

**Solutions:**
```bash
# Add database indexes
kubectl exec -it deployment/mysql -n task-management -- mysql -u root -p taskdb -e "
CREATE INDEX idx_created_at ON tasks(created_at);
CREATE INDEX idx_status_created ON tasks(status, created_at);
"

# Optimize MySQL configuration
kubectl patch deployment mysql -n task-management -p '{"spec":{"template":{"spec":{"containers":[{"name":"mysql","env":[{"name":"MYSQL_INNODB_BUFFER_POOL_SIZE","value":"1G"}]}]}}}}'

# Scale database resources
kubectl patch deployment mysql -n task-management -p '{"spec":{"template":{"spec":{"containers":[{"name":"mysql","resources":{"limits":{"memory":"4Gi","cpu":"2000m"}}}]}}}}'
```

### Networking Issues

#### Service Not Accessible

**Symptoms:**
- 503 Service Unavailable errors
- Connection timeouts
- DNS resolution failures

**Diagnosis:**
```bash
# Check service endpoints
kubectl get endpoints -n task-management

# Test service connectivity
kubectl run test-pod --image=busybox -it --rm -- nslookup task-api-service.task-management.svc.cluster.local

# Check ingress status
kubectl describe ingress task-api-ingress -n task-management
```

**Solutions:**
```bash
# Restart ingress controller
kubectl rollout restart deployment/nginx-ingress-controller -n ingress-nginx

# Update service selector
kubectl patch service task-api-service -n task-management -p '{"spec":{"selector":{"app":"task-api"}}}'

# Check network policies
kubectl get networkpolicy -n task-management
```

#### Ingress Not Working

**Symptoms:**
- 404 Not Found from ingress
- SSL certificate issues
- Ingress controller errors

**Diagnosis:**
```bash
# Check ingress controller logs
kubectl logs -f deployment/nginx-ingress-controller -n ingress-nginx

# Check certificate status
kubectl describe certificate task-api-tls -n task-management

# Test ingress rules
kubectl get ingress task-api-ingress -n task-management -o yaml
```

**Solutions:**
```bash
# Update ingress annotations
kubectl annotate ingress task-api-ingress -n task-management nginx.ingress.kubernetes.io/rewrite-target=/

# Recreate certificate
kubectl delete certificate task-api-tls -n task-management
kubectl apply -f k8s/ingress.yaml

# Check DNS configuration
nslookup api.taskmanagement.local
```

### Kubernetes Issues

#### Pods Stuck in Pending

**Symptoms:**
- Pods remain in Pending state
- Insufficient resources warnings
- Scheduling failures

**Diagnosis:**
```bash
# Check pod events
kubectl describe pod <pod-name> -n task-management

# Check node resources
kubectl top nodes

# Check resource quotas
kubectl describe resourcequota -n task-management
```

**Solutions:**
```bash
# Scale cluster nodes (if using managed service)
# AWS EKS example:
aws eks update-nodegroup --cluster-name task-management-cluster --nodegroup-name main-nodes --scaling-config minSize=2,maxSize=10,desiredSize=4

# Reduce resource requests
kubectl patch deployment task-api -n task-management -p '{"spec":{"template":{"spec":{"containers":[{"name":"task-api","resources":{"requests":{"memory":"256Mi","cpu":"100m"}}}]}}}}'

# Check and remove resource quotas if needed
kubectl delete resourcequota <quota-name> -n task-management
```

#### PVC Stuck in Pending

**Symptoms:**
- PersistentVolumeClaim in Pending state
- No available storage
- StorageClass issues

**Diagnosis:**
```bash
# Check PVC status
kubectl describe pvc mysql-pvc -n task-management

# Check available storage classes
kubectl get storageclass

# Check persistent volumes
kubectl get pv
```

**Solutions:**
```bash
# Create storage class if missing
kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp2
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp2
  fsType: ext4
EOF

# Update PVC storage class
kubectl patch pvc mysql-pvc -n task-management -p '{"spec":{"storageClassName":"gp2"}}'
```

### Monitoring Issues

#### Prometheus Not Scraping Metrics

**Symptoms:**
- Missing metrics in Prometheus
- Targets showing as down
- No data in Grafana dashboards

**Diagnosis:**
```bash
# Check Prometheus targets
curl http://prometheus.taskmanagement.local/targets

# Check service monitor
kubectl get servicemonitor -n monitoring

# Test metrics endpoint
kubectl exec -it deployment/task-api -n task-management -- curl localhost:8080/actuator/prometheus
```

**Solutions:**
```bash
# Update service monitor labels
kubectl patch servicemonitor task-api -n monitoring -p '{"spec":{"selector":{"matchLabels":{"app":"task-api"}}}}'

# Restart Prometheus
kubectl rollout restart deployment/prometheus -n monitoring

# Check network policies
kubectl get networkpolicy -n monitoring
```

#### Grafana Dashboards Not Loading

**Symptoms:**
- Empty dashboards
- "No data" messages
- Dashboard import failures

**Diagnosis:**
```bash
# Check Grafana logs
kubectl logs -f deployment/grafana -n monitoring

# Check datasource configuration
kubectl exec -it deployment/grafana -n monitoring -- curl localhost:3000/api/datasources

# Test Prometheus connectivity
kubectl exec -it deployment/grafana -n monitoring -- curl prometheus-service:9090/api/v1/query?query=up
```

**Solutions:**
```bash
# Update datasource URL
kubectl patch configmap grafana-datasources -n monitoring -p '{"data":{"datasources.yaml":"apiVersion: 1\ndatasources:\n- name: Prometheus\n  type: prometheus\n  url: http://prometheus-service:9090\n  access: proxy\n  isDefault: true"}}'

# Restart Grafana
kubectl rollout restart deployment/grafana -n monitoring

# Reimport dashboards
kubectl delete configmap grafana-dashboards -n monitoring
kubectl apply -f monitoring/grafana/dashboards/
```

## Performance Troubleshooting

### High CPU Usage

**Diagnosis:**
```bash
# Check CPU usage
kubectl top pods -n task-management

# Check JVM thread dump
kubectl exec -it deployment/task-api -n task-management -- jstack <pid>

# Check application metrics
curl http://localhost:8080/actuator/metrics/system.cpu.usage
```

**Solutions:**
```bash
# Scale horizontally
kubectl scale deployment task-api --replicas=5 -n task-management

# Optimize JVM garbage collection
kubectl patch deployment task-api -n task-management -p '{"spec":{"template":{"spec":{"containers":[{"name":"task-api","env":[{"name":"JAVA_OPTS","value":"-XX:+UseG1GC -XX:MaxGCPauseMillis=200"}]}]}}}}'

# Add CPU limits
kubectl patch deployment task-api -n task-management -p '{"spec":{"template":{"spec":{"containers":[{"name":"task-api","resources":{"limits":{"cpu":"1000m"}}}]}}}}'
```

### Memory Leaks

**Diagnosis:**
```bash
# Monitor memory usage over time
kubectl top pods -n task-management --sort-by=memory

# Generate heap dump
kubectl exec -it deployment/task-api -n task-management -- jcmd <pid> GC.run_finalization

# Check for memory leaks in application code
# Review connection pools, caches, and static collections
```

**Solutions:**
```bash
# Restart pods periodically (temporary fix)
kubectl rollout restart deployment/task-api -n task-management

# Implement proper resource cleanup in application code
# Add connection pool monitoring
# Review caching strategies
```

## Debugging Commands

### Application Debugging
```bash
# Get application logs
kubectl logs -f deployment/task-api -n task-management

# Execute commands in pod
kubectl exec -it deployment/task-api -n task-management -- bash

# Port forward for local debugging
kubectl port-forward deployment/task-api 8080:8080 -n task-management

# Check application configuration
kubectl exec -it deployment/task-api -n task-management -- env | grep SPRING
```

### Database Debugging
```bash
# Connect to database
kubectl exec -it deployment/mysql -n task-management -- mysql -u root -p taskdb

# Check database status
kubectl exec -it deployment/mysql -n task-management -- mysqladmin status -u root -p

# Monitor database queries
kubectl exec -it deployment/mysql -n task-management -- mysql -u root -p -e "SHOW PROCESSLIST;"
```

### Network Debugging
```bash
# Test connectivity between pods
kubectl exec -it deployment/task-api -n task-management -- nc -zv mysql-service 3306

# Check DNS resolution
kubectl exec -it deployment/task-api -n task-management -- nslookup mysql-service

# Test external connectivity
kubectl exec -it deployment/task-api -n task-management -- curl -I https://google.com
```

## Emergency Procedures

### Application Down
```bash
# Quick restart
kubectl rollout restart deployment/task-api -n task-management

# Scale to zero and back (if restart doesn't work)
kubectl scale deployment task-api --replicas=0 -n task-management
kubectl scale deployment task-api --replicas=3 -n task-management

# Rollback to previous version
kubectl rollout undo deployment/task-api -n task-management
```

### Database Corruption
```bash
# Stop application
kubectl scale deployment task-api --replicas=0 -n task-management

# Backup current database
kubectl exec -it deployment/mysql -n task-management -- mysqldump -u root -p taskdb > emergency-backup.sql

# Restore from backup
kubectl exec -i deployment/mysql -n task-management -- mysql -u root -p taskdb < last-good-backup.sql

# Restart application
kubectl scale deployment task-api --replicas=3 -n task-management
```

### Complete System Recovery
```bash
# Delete and recreate namespace
kubectl delete namespace task-management
kubectl apply -f k8s/

# Restore from backup
kubectl exec -i deployment/mysql -n task-management -- mysql -u root -p taskdb < backup.sql

# Verify system health
kubectl get all -n task-management
curl http://api.taskmanagement.local/actuator/health
```

This troubleshooting guide covers the most common issues and their solutions for the Task Management API deployment.
```

# Task Management System - Testing Guide

## 🧪 Complete Testing with Sample Data

### Prerequisites
- System running: `sudo docker compose up -d`
- All containers healthy: `sudo docker compose ps`

## 📊 Sample Test Data

### 1. Create Sample Tasks via API

```bash
# Task 1: Backend Development
curl -X POST http://localhost:8080/api/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Implement user authentication API",
    "description": "Create JWT-based authentication system with refresh tokens",
    "priority": "HIGH",
    "completed": false
  }'

# Task 2: Design Work
curl -X POST http://localhost:8080/api/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Design user registration flow",
    "description": "Create wireframes and mockups for user registration process",
    "priority": "MEDIUM",
    "completed": true
  }'

# Task 3: Critical Bug Fix
curl -X POST http://localhost:8080/api/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Fix payment gateway timeout issue",
    "description": "Payment processing fails after 30 seconds, investigate and fix",
    "priority": "HIGH",
    "completed": false
  }'

# Task 4: QA Testing
curl -X POST http://localhost:8080/api/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test checkout process on mobile",
    "description": "Comprehensive testing of mobile checkout flow across devices",
    "priority": "HIGH",
    "completed": false
  }'

# Task 5: DevOps Work
curl -X POST http://localhost:8080/api/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Deploy staging environment",
    "description": "Set up staging server with latest code and database migration",
    "priority": "HIGH",
    "completed": false
  }'

# Task 6: Documentation
curl -X POST http://localhost:8080/api/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Update API documentation",
    "description": "Document new authentication endpoints and payment APIs",
    "priority": "MEDIUM",
    "completed": false
  }'

# Task 7: Security Audit
curl -X POST http://localhost:8080/api/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Security audit - Authentication module",
    "description": "Perform security review of authentication implementation",
    "priority": "HIGH",
    "completed": false
  }'

# Task 8: Client Demo
curl -X POST http://localhost:8080/api/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Prepare demo for client meeting",
    "description": "Create presentation and demo environment for client showcase",
    "priority": "HIGH",
    "completed": false
  }'

# Task 9: Database Optimization
curl -X POST http://localhost:8080/api/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Database performance optimization",
    "description": "Optimize slow queries and add proper indexing",
    "priority": "MEDIUM",
    "completed": false
  }'

# Task 10: HR Recruitment
curl -X POST http://localhost:8080/api/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Recruit senior frontend developer",
    "description": "Interview and hire experienced React developer for team expansion",
    "priority": "MEDIUM",
    "completed": false
  }'
```

### 2. Bulk Insert Script

```bash
# Create bulk insert script
cat > insert_sample_tasks.sh << 'EOF'
#!/bin/bash

API_URL="http://localhost:8080/api/tasks"

echo "🚀 Inserting sample tasks..."

# Array of sample tasks
declare -a tasks=(
  '{"title": "Implement user authentication API", "description": "Create JWT-based authentication system with refresh tokens", "priority": "HIGH", "completed": false}'
  '{"title": "Design user registration flow", "description": "Create wireframes and mockups for user registration process", "priority": "MEDIUM", "completed": true}'
  '{"title": "Fix payment gateway timeout issue", "description": "Payment processing fails after 30 seconds, investigate and fix", "priority": "HIGH", "completed": false}'
  '{"title": "Test checkout process on mobile", "description": "Comprehensive testing of mobile checkout flow across devices", "priority": "HIGH", "completed": false}'
  '{"title": "Deploy staging environment", "description": "Set up staging server with latest code and database migration", "priority": "HIGH", "completed": false}'
  '{"title": "Update API documentation", "description": "Document new authentication endpoints and payment APIs", "priority": "MEDIUM", "completed": false}'
  '{"title": "Security audit - Authentication module", "description": "Perform security review of authentication implementation", "priority": "HIGH", "completed": false}'
  '{"title": "Prepare demo for client meeting", "description": "Create presentation and demo environment for client showcase", "priority": "HIGH", "completed": false}'
  '{"title": "Database performance optimization", "description": "Optimize slow queries and add proper indexing", "priority": "MEDIUM", "completed": false}'
  '{"title": "Recruit senior frontend developer", "description": "Interview and hire experienced React developer for team expansion", "priority": "MEDIUM", "completed": false}'
)

# Insert each task
for i in "${!tasks[@]}"; do
  echo "Inserting task $((i+1))/10..."
  curl -X POST "$API_URL" \
    -H "Content-Type: application/json" \
    -d "${tasks[$i]}" \
    -s -o /dev/null
  sleep 0.5
done

echo "✅ All sample tasks inserted!"
echo "📊 View tasks at: http://localhost:3001"
EOF

chmod +x insert_sample_tasks.sh
./insert_sample_tasks.sh
```

## 🔍 API Testing Commands

### Basic CRUD Operations

```bash
# 1. Get all tasks
curl -X GET http://localhost:8080/api/tasks | jq

# 2. Get specific task
curl -X GET http://localhost:8080/api/tasks/1 | jq

# 3. Update task (mark as completed)
curl -X PUT http://localhost:8080/api/tasks/1 \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Implement user authentication API",
    "description": "Create JWT-based authentication system with refresh tokens",
    "priority": "HIGH",
    "completed": true
  }' | jq

# 4. Delete task
curl -X DELETE http://localhost:8080/api/tasks/10

# 5. Create new task
curl -X POST http://localhost:8080/api/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "New Test Task",
    "description": "Testing API functionality",
    "priority": "LOW",
    "completed": false
  }' | jq
```

### Advanced Testing Scenarios

```bash
# Test with special characters
curl -X POST http://localhost:8080/api/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Special Characters: @#$%^&*()",
    "description": "Testing with special chars: <>?{}[]|\\",
    "priority": "LOW",
    "completed": false
  }'

# Test with long description
curl -X POST http://localhost:8080/api/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Long Description Test",
    "description": "This is a very long description that tests the database field limits and ensures that our application can handle lengthy text inputs without any issues. It should be stored properly in the MySQL database and displayed correctly in the frontend interface.",
    "priority": "MEDIUM",
    "completed": false
  }'

# Test with empty description
curl -X POST http://localhost:8080/api/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Empty Description Test",
    "description": "",
    "priority": "LOW",
    "completed": false
  }'
```

## 🗄️ Database Testing

### Direct MySQL Queries

```bash
# Connect to MySQL container
sudo docker exec -it task-mysql mysql -u taskuser -ptaskpass taskdb

# Once connected, run these SQL queries:
```

```sql
-- View all tasks
SELECT * FROM tasks;

-- Count tasks by priority
SELECT priority, COUNT(*) as count FROM tasks GROUP BY priority;

-- Count completed vs pending tasks
SELECT completed, COUNT(*) as count FROM tasks GROUP BY completed;

-- Find high priority incomplete tasks
SELECT id, title, priority, completed FROM tasks 
WHERE priority = 'HIGH' AND completed = false;

-- Search tasks by title keyword
SELECT id, title, description FROM tasks 
WHERE title LIKE '%authentication%' OR description LIKE '%authentication%';

-- Tasks ordered by creation date
SELECT id, title, created_at FROM tasks ORDER BY created_at DESC;

-- Update task status
UPDATE tasks SET completed = true WHERE id = 3;

-- Delete completed tasks
DELETE FROM tasks WHERE completed = true;

-- Exit MySQL
EXIT;
```

### Database Schema Verification

```bash
# Check table structure
sudo docker exec -it task-mysql mysql -u taskuser -ptaskpass taskdb -e "DESCRIBE tasks;"

# Check indexes
sudo docker exec -it task-mysql mysql -u taskuser -ptaskpass taskdb -e "SHOW INDEX FROM tasks;"

# Check table size
sudo docker exec -it task-mysql mysql -u taskuser -ptaskpass taskdb -e "SELECT COUNT(*) as total_tasks FROM tasks;"
```

## 🌐 Frontend Testing

### Manual Testing Steps

1. **Open Frontend Dashboard**
   ```bash
   # Open in browser
   http://localhost:3001
   ```

2. **Test Task Creation**
   - Fill out the form with sample data
   - Test all priority levels (LOW, MEDIUM, HIGH)
   - Verify task appears in list immediately

3. **Test Task Management**
   - Mark tasks as complete
   - Delete tasks
   - Verify statistics update in real-time

4. **Test Edge Cases**
   - Create task with very long title
   - Create task with empty description
   - Test special characters in title/description

### Automated Frontend Testing

```bash
# Test frontend API connectivity
curl -X GET http://localhost:3001/api/tasks

# Test frontend static files
curl -I http://localhost:3001/
curl -I http://localhost:3001/css/style.css
curl -I http://localhost:3001/js/script.js

# Test CORS headers
curl -H "Origin: http://localhost:3001" \
     -H "Access-Control-Request-Method: POST" \
     -H "Access-Control-Request-Headers: Content-Type" \
     -X OPTIONS http://localhost:3001/api/tasks
```

## 📊 Performance Testing

### Load Testing with curl

```bash
# Create multiple tasks simultaneously
for i in {1..20}; do
  curl -X POST http://localhost:8080/api/tasks \
    -H "Content-Type: application/json" \
    -d "{
      \"title\": \"Load Test Task $i\",
      \"description\": \"Performance testing task number $i\",
      \"priority\": \"MEDIUM\",
      \"completed\": false
    }" &
done
wait

echo "Load test completed - check task count"
curl -X GET http://localhost:8080/api/tasks | jq length
```

### Response Time Testing

```bash
# Measure API response time
time curl -X GET http://localhost:8080/api/tasks > /dev/null

# Test with large dataset
for i in {1..100}; do
  curl -X POST http://localhost:8080/api/tasks \
    -H "Content-Type: application/json" \
    -d "{\"title\": \"Bulk Task $i\", \"description\": \"Testing with large dataset\", \"priority\": \"LOW\", \"completed\": false}" \
    -s -o /dev/null
done

# Measure response time with 100 tasks
time curl -X GET http://localhost:8080/api/tasks > /dev/null
```

## 🔍 Monitoring & Health Checks

### Application Health

```bash
# Backend health check
curl http://localhost:8080/actuator/health | jq

# Database connectivity
curl http://localhost:8080/actuator/health/db | jq

# Application metrics
curl http://localhost:8080/actuator/metrics | jq

# Prometheus metrics
curl http://localhost:8080/actuator/prometheus
```

### Container Health

```bash
# Check all container status
sudo docker compose ps

# Check container logs
sudo docker compose logs app
sudo docker compose logs frontend
sudo docker compose logs mysql

# Check resource usage
sudo docker stats
```

## 🧪 Integration Testing

### End-to-End Test Script

```bash
cat > e2e_test.sh << 'EOF'
#!/bin/bash

echo "🧪 Starting End-to-End Testing..."

# Test 1: Health Check
echo "1. Testing application health..."
health=$(curl -s http://localhost:8080/actuator/health | jq -r '.status')
if [ "$health" = "UP" ]; then
  echo "✅ Backend health check passed"
else
  echo "❌ Backend health check failed"
  exit 1
fi

# Test 2: Create Task
echo "2. Testing task creation..."
task_id=$(curl -s -X POST http://localhost:8080/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"title": "E2E Test Task", "description": "Testing end-to-end functionality", "priority": "HIGH", "completed": false}' \
  | jq -r '.id')

if [ "$task_id" != "null" ]; then
  echo "✅ Task creation passed (ID: $task_id)"
else
  echo "❌ Task creation failed"
  exit 1
fi

# Test 3: Retrieve Task
echo "3. Testing task retrieval..."
task_title=$(curl -s http://localhost:8080/api/tasks/$task_id | jq -r '.title')
if [ "$task_title" = "E2E Test Task" ]; then
  echo "✅ Task retrieval passed"
else
  echo "❌ Task retrieval failed"
  exit 1
fi

# Test 4: Update Task
echo "4. Testing task update..."
curl -s -X PUT http://localhost:8080/api/tasks/$task_id \
  -H "Content-Type: application/json" \
  -d '{"title": "E2E Test Task", "description": "Updated description", "priority": "HIGH", "completed": true}' > /dev/null

completed=$(curl -s http://localhost:8080/api/tasks/$task_id | jq -r '.completed')
if [ "$completed" = "true" ]; then
  echo "✅ Task update passed"
else
  echo "❌ Task update failed"
  exit 1
fi

# Test 5: Delete Task
echo "5. Testing task deletion..."
curl -s -X DELETE http://localhost:8080/api/tasks/$task_id > /dev/null
status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/api/tasks/$task_id)
if [ "$status" = "404" ]; then
  echo "✅ Task deletion passed"
else
  echo "❌ Task deletion failed"
  exit 1
fi

# Test 6: Frontend Accessibility
echo "6. Testing frontend accessibility..."
frontend_status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3001)
if [ "$frontend_status" = "200" ]; then
  echo "✅ Frontend accessibility passed"
else
  echo "❌ Frontend accessibility failed"
  exit 1
fi

echo "🎉 All E2E tests passed!"
EOF

chmod +x e2e_test.sh
./e2e_test.sh
```

## 📈 Results Verification

### Expected Outcomes

1. **Database**: 10 sample tasks inserted
2. **API**: All CRUD operations working
3. **Frontend**: Tasks displayed with statistics
4. **Monitoring**: Metrics available in Prometheus
5. **Performance**: Response times under 500ms

### Verification Commands

```bash
# Count total tasks
curl -s http://localhost:8080/api/tasks | jq length

# Check completed tasks
curl -s http://localhost:8080/api/tasks | jq '[.[] | select(.completed == true)] | length'

# Check high priority tasks
curl -s http://localhost:8080/api/tasks | jq '[.[] | select(.priority == "HIGH")] | length'

# Verify frontend shows same data
echo "Open http://localhost:3001 and verify task count matches API"
```

## 🎯 Success Criteria

- ✅ All 10 sample tasks created successfully
- ✅ Frontend displays tasks with correct statistics
- ✅ CRUD operations work via API and frontend
- ✅ Database queries return expected results
- ✅ Monitoring shows healthy metrics
- ✅ Performance meets acceptable thresholds

**🎉 Your Task Management System is fully tested and production-ready!**

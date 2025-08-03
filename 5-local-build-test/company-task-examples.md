# Company Task Management - Role-Based Examples

## 🏢 Company: TechCorp Solutions (Software Development Company)
**Team Size**: 50 employees  
**Project**: E-commerce Platform Development

## 📋 All Tasks in System (Master List)

### Development Tasks
```json
{
  "id": 1001,
  "title": "Implement user authentication API",
  "description": "Create JWT-based authentication system with refresh tokens",
  "assignedTo": "john.doe",
  "reporter": "product.manager",
  "status": "IN_PROGRESS",
  "priority": "HIGH",
  "department": "ENGINEERING",
  "team": "backend",
  "project": "ecommerce-platform",
  "dueDate": "2024-01-20",
  "estimatedHours": 16,
  "tags": ["backend", "security", "api"]
}

{
  "id": 1002,
  "title": "Design user registration flow",
  "description": "Create wireframes and mockups for user registration process",
  "assignedTo": "sarah.designer",
  "reporter": "ux.lead",
  "status": "COMPLETED",
  "priority": "MEDIUM",
  "department": "DESIGN",
  "team": "ux-design",
  "project": "ecommerce-platform",
  "dueDate": "2024-01-15",
  "estimatedHours": 8,
  "tags": ["design", "ux", "wireframes"]
}

{
  "id": 1003,
  "title": "Fix payment gateway timeout issue",
  "description": "Payment processing fails after 30 seconds, investigate and fix",
  "assignedTo": "mike.senior",
  "reporter": "qa.tester",
  "status": "URGENT",
  "priority": "CRITICAL",
  "department": "ENGINEERING",
  "team": "backend",
  "project": "ecommerce-platform",
  "dueDate": "2024-01-16",
  "estimatedHours": 4,
  "tags": ["bug", "payment", "critical"]
}

{
  "id": 1004,
  "title": "Test checkout process on mobile",
  "description": "Comprehensive testing of mobile checkout flow across devices",
  "assignedTo": "lisa.qa",
  "reporter": "qa.lead",
  "status": "PENDING",
  "priority": "HIGH",
  "department": "QA",
  "team": "quality-assurance",
  "project": "ecommerce-platform",
  "dueDate": "2024-01-22",
  "estimatedHours": 12,
  "tags": ["testing", "mobile", "checkout"]
}

{
  "id": 1005,
  "title": "Deploy staging environment",
  "description": "Set up staging server with latest code and database migration",
  "assignedTo": "alex.devops",
  "reporter": "tech.lead",
  "status": "IN_PROGRESS",
  "priority": "HIGH",
  "department": "DEVOPS",
  "team": "infrastructure",
  "project": "ecommerce-platform",
  "dueDate": "2024-01-18",
  "estimatedHours": 6,
  "tags": ["deployment", "staging", "infrastructure"]
}

{
  "id": 1006,
  "title": "Update API documentation",
  "description": "Document new authentication endpoints and payment APIs",
  "assignedTo": "emma.writer",
  "reporter": "tech.lead",
  "status": "ASSIGNED",
  "priority": "MEDIUM",
  "department": "DOCUMENTATION",
  "team": "technical-writing",
  "project": "ecommerce-platform",
  "dueDate": "2024-01-25",
  "estimatedHours": 10,
  "tags": ["documentation", "api", "technical-writing"]
}

{
  "id": 1007,
  "title": "Security audit - Authentication module",
  "description": "Perform security review of authentication implementation",
  "assignedTo": "david.security",
  "reporter": "security.lead",
  "status": "SCHEDULED",
  "priority": "HIGH",
  "department": "SECURITY",
  "team": "security",
  "project": "ecommerce-platform",
  "dueDate": "2024-01-30",
  "estimatedHours": 8,
  "tags": ["security", "audit", "authentication"]
}

{
  "id": 1008,
  "title": "Prepare demo for client meeting",
  "description": "Create presentation and demo environment for client showcase",
  "assignedTo": "robert.pm",
  "reporter": "sales.director",
  "status": "PENDING",
  "priority": "HIGH",
  "department": "PROJECT_MANAGEMENT",
  "team": "project-management",
  "project": "ecommerce-platform",
  "dueDate": "2024-01-19",
  "estimatedHours": 4,
  "tags": ["demo", "client", "presentation"]
}

{
  "id": 1009,
  "title": "Database performance optimization",
  "description": "Optimize slow queries and add proper indexing",
  "assignedTo": "tom.dba",
  "reporter": "tech.lead",
  "status": "IN_PROGRESS",
  "priority": "MEDIUM",
  "department": "ENGINEERING",
  "team": "database",
  "project": "ecommerce-platform",
  "dueDate": "2024-01-28",
  "estimatedHours": 20,
  "tags": ["database", "performance", "optimization"]
}

{
  "id": 1010,
  "title": "Recruit senior frontend developer",
  "description": "Interview and hire experienced React developer for team expansion",
  "assignedTo": "hr.manager",
  "reporter": "engineering.director",
  "status": "IN_PROGRESS",
  "priority": "MEDIUM",
  "department": "HR",
  "team": "human-resources",
  "project": "team-expansion",
  "dueDate": "2024-02-15",
  "estimatedHours": 40,
  "tags": ["recruitment", "frontend", "hiring"]
}
```

## 🔍 Role-Based Task Filtering

### 1. **Backend Developer** (john.doe)
```bash
GET /api/tasks?assignedTo=john.doe&department=ENGINEERING

# John sees only his engineering tasks:
[
  {
    "id": 1001,
    "title": "Implement user authentication API",
    "status": "IN_PROGRESS",
    "priority": "HIGH",
    "dueDate": "2024-01-20"
  }
]
```

### 2. **QA Tester** (lisa.qa)
```bash
GET /api/tasks?assignedTo=lisa.qa&department=QA

# Lisa sees her testing tasks:
[
  {
    "id": 1004,
    "title": "Test checkout process on mobile",
    "status": "PENDING",
    "priority": "HIGH",
    "dueDate": "2024-01-22"
  }
]
```

### 3. **Team Lead** (tech.lead)
```bash
GET /api/tasks?team=backend&status=IN_PROGRESS,PENDING,URGENT

# Tech Lead sees all backend team tasks:
[
  {
    "id": 1001,
    "title": "Implement user authentication API",
    "assignedTo": "john.doe",
    "status": "IN_PROGRESS"
  },
  {
    "id": 1003,
    "title": "Fix payment gateway timeout issue",
    "assignedTo": "mike.senior",
    "status": "URGENT"
  },
  {
    "id": 1009,
    "title": "Database performance optimization",
    "assignedTo": "tom.dba",
    "status": "IN_PROGRESS"
  }
]
```

### 4. **Project Manager** (robert.pm)
```bash
GET /api/tasks?project=ecommerce-platform&priority=HIGH,CRITICAL

# PM sees all high-priority project tasks:
[
  {
    "id": 1001,
    "title": "Implement user authentication API",
    "assignedTo": "john.doe",
    "priority": "HIGH"
  },
  {
    "id": 1003,
    "title": "Fix payment gateway timeout issue",
    "assignedTo": "mike.senior",
    "priority": "CRITICAL"
  },
  {
    "id": 1004,
    "title": "Test checkout process on mobile",
    "assignedTo": "lisa.qa",
    "priority": "HIGH"
  },
  {
    "id": 1008,
    "title": "Prepare demo for client meeting",
    "assignedTo": "robert.pm",
    "priority": "HIGH"
  }
]
```

### 5. **DevOps Engineer** (alex.devops)
```bash
GET /api/tasks?assignedTo=alex.devops&department=DEVOPS

# DevOps sees infrastructure tasks:
[
  {
    "id": 1005,
    "title": "Deploy staging environment",
    "status": "IN_PROGRESS",
    "priority": "HIGH",
    "dueDate": "2024-01-18"
  }
]
```

### 6. **HR Manager** (hr.manager)
```bash
GET /api/tasks?department=HR&assignedTo=hr.manager

# HR sees only HR-related tasks:
[
  {
    "id": 1010,
    "title": "Recruit senior frontend developer",
    "status": "IN_PROGRESS",
    "priority": "MEDIUM",
    "dueDate": "2024-02-15"
  }
]
```

### 7. **Security Specialist** (david.security)
```bash
GET /api/tasks?department=SECURITY&assignedTo=david.security

# Security sees security-related tasks:
[
  {
    "id": 1007,
    "title": "Security audit - Authentication module",
    "status": "SCHEDULED",
    "priority": "HIGH",
    "dueDate": "2024-01-30"
  }
]
```

### 8. **Engineering Director** (engineering.director)
```bash
GET /api/tasks?department=ENGINEERING,DEVOPS&priority=HIGH,CRITICAL

# Director sees all engineering tasks by priority:
[
  {
    "id": 1001,
    "title": "Implement user authentication API",
    "team": "backend",
    "assignedTo": "john.doe",
    "priority": "HIGH"
  },
  {
    "id": 1003,
    "title": "Fix payment gateway timeout issue",
    "team": "backend", 
    "assignedTo": "mike.senior",
    "priority": "CRITICAL"
  },
  {
    "id": 1005,
    "title": "Deploy staging environment",
    "team": "infrastructure",
    "assignedTo": "alex.devops",
    "priority": "HIGH"
  }
]
```

## 📊 Dashboard Views by Role

### **Developer Dashboard** (john.doe)
```
┌─────────────────────────────────────────────────────┐
│  My Tasks - John Doe (Backend Developer)            │
├─────────────────────────────────────────────────────┤
│  🔴 IN PROGRESS (1)                                │
│  └─ Implement user authentication API               │
│     Due: Jan 20 | 16h estimated | HIGH priority     │
│                                                     │
│  📋 TEAM UPDATES                                   │
│  └─ Mike: Fixed payment gateway bug ✅             │
│  └─ Tom: Database optimization 60% complete         │
└─────────────────────────────────────────────────────┘
```

### **QA Dashboard** (lisa.qa)
```
┌─────────────────────────────────────────────────────┐
│  QA Tasks - Lisa (QA Tester)                        │
├─────────────────────────────────────────────────────┤
│  ⏳ PENDING (1)                                    │
│  └─ Test checkout process on mobile                 │
│     Due: Jan 22 | 12h estimated | HIGH priority     │
│                                                     │
│  🐛 BUGS TO VERIFY                                  │
│  └─ Payment gateway fix (waiting for dev)           │
└─────────────────────────────────────────────────────┘
```

### **Project Manager Dashboard** (robert.pm)
```
┌─────────────────────────────────────────────────────┐
│  Project Overview - E-commerce Platform             │
├─────────────────────────────────────────────────────┤
│  🚨 CRITICAL ISSUES (1)                            │
│  └─ Payment gateway timeout - Mike (In Progress)    │
│                                                     │
│  📈 PROJECT PROGRESS                               │
│  ├─ Backend: 65% complete                           │
│  ├─ Frontend: 45% complete                          │
│  ├─ QA: 30% complete                                │
│  └─ DevOps: 80% complete                            │
│                                                     │
│  ⏰ UPCOMING DEADLINES                             │
│  ├─ Jan 18: Staging deployment                      │
│  ├─ Jan 19: Client demo preparation                 │
│  └─ Jan 20: Authentication API                      │
└─────────────────────────────────────────────────────┘
```

### **Team Lead Dashboard** (tech.lead)
```
┌─────────────────────────────────────────────────────┐
│  Backend Team Status                                │
├─────────────────────────────────────────────────────┤
│  👥 TEAM WORKLOAD                                  │
│  ├─ John Doe: 1 task (HIGH load)                    │
│  ├─ Mike Senior: 1 task (CRITICAL)                  │
│  └─ Tom DBA: 1 task (MEDIUM load)                   │
│                                                     │
│  🔥 URGENT ITEMS                                   │
│  └─ Payment gateway fix needs immediate attention   │
│                                                     │
│  📋 BLOCKERS                                       │
│  └─ None currently                                  │
└─────────────────────────────────────────────────────┘
```

## 🔔 Notification Examples by Role

### **Developer Notifications**
```
🔔 New task assigned: "Implement user authentication API"
🔔 Code review requested by Sarah on PR #123
🔔 Build failed for feature/auth-api branch
🔔 @mike.senior mentioned you in "Payment gateway fix"
```

### **QA Notifications**
```
🔔 Ready for testing: "User registration flow" 
🔔 Bug reported: "Checkout fails on Safari"
🔔 Test environment updated with latest build
🔔 Regression test suite completed - 2 failures
```

### **Project Manager Notifications**
```
🔔 CRITICAL: Payment gateway issue reported
🔔 Milestone "Authentication Module" 80% complete
🔔 Client meeting scheduled for Jan 19 - demo needed
🔔 Team velocity: 23 story points this sprint
```

### **DevOps Notifications**
```
🔔 Staging deployment requested by tech lead
🔔 Production server CPU usage >85% for 10 minutes
🔔 SSL certificate expires in 30 days
🔔 Database backup completed successfully
```

## 🎯 Real-World Usage Scenarios

#### Where to Check Created Tasks
**1. API Endpoints (Direct Access)**
```bash
# Check all tasks you created
curl http://localhost:8080/api/tasks

# Check specific task by ID
curl http://localhost:8080/api/tasks/1

# Check tasks assigned to you
curl "http://localhost:8080/api/tasks?assignedTo=john.doe"

# Check tasks by status
curl "http://localhost:8080/api/tasks?status=PENDING"
```

**2. Database (Direct Storage)**
```bash
# Connect to MySQL database
sudo docker exec -it task-mysql mysql -u taskuser -p taskdb
# Password: taskpass
```
```sql
# View all tasks in database
SELECT * FROM tasks;

# View specific columns
SELECT id, title, status, created_at FROM tasks;

# Exit database
EXIT;
```

**3. Application Logs**
```bash
# Check application logs for task creation
sudo docker logs task-api | grep -i "task"

# Real-time log monitoring
sudo docker logs -f task-api
```

**4. Grafana Dashboard (Visual Monitoring)**

**URL** : http://localhost:3000

**Login** : admin/admin123

**Dashboard** : "Task Management API Monitoring"

**Panels** : Shows request counts, API activity

**5. Prometheus Metrics (System Monitoring)**
**URL** : http://localhost:9090

**Query** : http_server_requests_seconds_count{uri="/api/tasks"}

**Shows** : How many API calls were made

### Quick Test Workflow:
```bash
# 1. Create a task
curl -X POST http://localhost:8080/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"title":"Test Task","description":"Testing"}'

# 2. Check if it was created
curl http://localhost:8080/api/tasks

# 3. Verify in database
sudo docker exec -it task-mysql mysql -u taskuser -p taskdb -e "SELECT * FROM tasks;"
```
**Most Common** : Use the API endpoint GET /api/tasks to see all created tasks in JSON format.

---

### **Morning Standup (9:00 AM)**
Each team member checks their role-specific dashboard:

- **John (Developer)**: "Working on auth API, 60% done, no blockers"
- **Lisa (QA)**: "Waiting for auth API to test, will start mobile testing"
- **Mike (Senior Dev)**: "Fixed payment bug, deploying to staging today"
- **Alex (DevOps)**: "Staging environment ready, production deploy scheduled"

### **Urgent Bug Report (2:30 PM)**
```bash
# QA reports critical bug
POST /api/tasks
{
  "title": "Payment processing down - all transactions failing",
  "priority": "CRITICAL",
  "assignedTo": "mike.senior",
  "reporter": "lisa.qa",
  "status": "URGENT"
}

# Notifications sent to:
# - Mike (assignee): Immediate Slack + email + mobile push
# - Tech Lead: Slack notification
# - Project Manager: Email alert
# - DevOps: Monitoring alert
```

### **End of Sprint (Friday 5:00 PM)**
```bash
# Project Manager reviews completed tasks
GET /api/tasks?project=ecommerce-platform&status=COMPLETED&dateRange=this-sprint

# Generates sprint report:
# - 15 tasks completed
# - 3 tasks carried over
# - Team velocity: 42 story points
# - 95% on-time delivery rate
```

## 🔐 Access Control Matrix

| Role | Can See | Can Edit | Can Assign | Can Delete |
|------|---------|----------|------------|------------|
| **Developer** | Own tasks + team tasks | Own tasks | No | No |
| **QA Tester** | Own tasks + bugs | Own tasks | No | No |
| **Team Lead** | Team tasks | Team tasks | Team members | Team tasks |
| **Project Manager** | Project tasks | All project tasks | Anyone | Project tasks |
| **DevOps** | Infrastructure tasks | Own tasks | No | No |
| **HR Manager** | HR tasks | HR tasks | HR team | HR tasks |
| **Director** | Department tasks | All tasks | Anyone | Any task |
| **Admin** | All tasks | All tasks | Anyone | Any task |

This role-based system ensures everyone sees **only relevant tasks** while maintaining proper **collaboration and oversight** across the organization! 🚀

# Task Management System - Local Setup Guide

## 🚀 Quick Start

```bash
# Clone repository
git clone <repository-url>
cd task-management-api

# Setup and run
cd 5-containerization
sudo docker compose up -d

# Access applications
# Frontend: http://localhost:3001
# Backend: http://localhost:8080
# Grafana: http://localhost:3000 (admin/admin123)
# Prometheus: http://localhost:9090
```

## 📋 Prerequisites

- **Docker**: Version 20.10+
- **Docker Compose**: Version 2.0+
- **Java**: 17+ (for local development)
- **Maven**: 3.6+ (for building JAR)
- **Git**: Latest version

### Installation Commands (Ubuntu)
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo apt-get update
sudo apt-get install docker-compose-plugin

# Install Java & Maven
sudo apt-get install openjdk-17-jdk maven

# Verify installations
docker --version
docker compose version
java -version
mvn -version
```

## 🏗️ Project Structure

```
task-management-api/
├── 2-source-code/              # Spring Boot backend
│   ├── src/
│   ├── pom.xml
│   └── Dockerfile
├── 3-frontend/                 # Frontend dashboard
│   ├── src/
│   │   ├── index.html
│   │   ├── css/style.css
│   │   └── js/script.js
│   ├── Dockerfile
│   └── nginx.conf
└── 5-containerization/         # Docker setup
    ├── docker-compose.yml
    └── prometheus.yml
```

## 🔧 Step-by-Step Setup

### 1. Prepare Backend
```bash
cd 2-source-code

# Fix pom.xml MySQL dependency (if needed)
# Add version to mysql-connector-java:
sed -i '/<artifactId>mysql-connector-java<\/artifactId>/a\            <version>8.0.33</version>' pom.xml

# Build JAR file
mvn clean package -DskipTests
```

### 2. Create Frontend Files
```bash
cd ../3-frontend

# Create directory structure
mkdir -p src/css src/js src/assets

# Create index.html
cat > src/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Task Management Dashboard</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
    <div class="container">
        <header>
            <h1>Task Management System</h1>
        </header>
        
        <div class="stats">
            <div class="stat-card">
                <h3>Total Tasks</h3>
                <span id="totalTasks">0</span>
            </div>
            <div class="stat-card">
                <h3>Completed</h3>
                <span id="completedTasks">0</span>
            </div>
            <div class="stat-card">
                <h3>Pending</h3>
                <span id="pendingTasks">0</span>
            </div>
        </div>

        <div class="task-form">
            <h2>Add New Task</h2>
            <form id="taskForm">
                <input type="text" id="taskTitle" placeholder="Task Title" required>
                <textarea id="taskDescription" placeholder="Task Description"></textarea>
                <select id="taskPriority">
                    <option value="LOW">Low</option>
                    <option value="MEDIUM">Medium</option>
                    <option value="HIGH">High</option>
                </select>
                <button type="submit">Add Task</button>
            </form>
        </div>

        <div class="tasks-section">
            <h2>Tasks</h2>
            <div id="tasksList"></div>
        </div>
    </div>

    <script src="js/script.js"></script>
</body>
</html>
EOF

# Create style.css
cat > src/css/style.css << 'EOF'
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: 'Arial', sans-serif;
    background-color: #f5f5f5;
    color: #333;
}

.container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 20px;
}

header {
    text-align: center;
    margin-bottom: 30px;
}

header h1 {
    color: #2c3e50;
    font-size: 2.5rem;
}

.stats {
    display: flex;
    gap: 20px;
    margin-bottom: 30px;
    justify-content: center;
}

.stat-card {
    background: white;
    padding: 20px;
    border-radius: 8px;
    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
    text-align: center;
    min-width: 150px;
}

.stat-card h3 {
    color: #7f8c8d;
    margin-bottom: 10px;
}

.stat-card span {
    font-size: 2rem;
    font-weight: bold;
    color: #3498db;
}

.task-form {
    background: white;
    padding: 30px;
    border-radius: 8px;
    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
    margin-bottom: 30px;
}

.task-form h2 {
    margin-bottom: 20px;
    color: #2c3e50;
}

.task-form form {
    display: flex;
    flex-direction: column;
    gap: 15px;
}

.task-form input, .task-form textarea, .task-form select {
    padding: 12px;
    border: 1px solid #ddd;
    border-radius: 4px;
    font-size: 16px;
}

.task-form button {
    background: #3498db;
    color: white;
    padding: 12px;
    border: none;
    border-radius: 4px;
    cursor: pointer;
    font-size: 16px;
}

.task-form button:hover {
    background: #2980b9;
}

.tasks-section {
    background: white;
    padding: 30px;
    border-radius: 8px;
    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
}

.tasks-section h2 {
    margin-bottom: 20px;
    color: #2c3e50;
}

.task-item {
    border: 1px solid #eee;
    border-radius: 4px;
    padding: 15px;
    margin-bottom: 10px;
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.task-item.completed {
    background-color: #d5f4e6;
    border-color: #27ae60;
}

.task-info h4 {
    margin-bottom: 5px;
    color: #2c3e50;
}

.task-info p {
    color: #7f8c8d;
    margin-bottom: 5px;
}

.task-priority {
    padding: 4px 8px;
    border-radius: 4px;
    font-size: 12px;
    font-weight: bold;
}

.priority-HIGH {
    background: #e74c3c;
    color: white;
}

.priority-MEDIUM {
    background: #f39c12;
    color: white;
}

.priority-LOW {
    background: #95a5a6;
    color: white;
}

.task-actions button {
    margin-left: 10px;
    padding: 5px 10px;
    border: none;
    border-radius: 4px;
    cursor: pointer;
}

.complete-btn {
    background: #27ae60;
    color: white;
}

.delete-btn {
    background: #e74c3c;
    color: white;
}
EOF

# Create script.js
cat > src/js/script.js << 'EOF'
const API_BASE_URL = '/api';

// DOM Elements
const taskForm = document.getElementById('taskForm');
const tasksList = document.getElementById('tasksList');
const totalTasksEl = document.getElementById('totalTasks');
const completedTasksEl = document.getElementById('completedTasks');
const pendingTasksEl = document.getElementById('pendingTasks');

// Load tasks on page load
document.addEventListener('DOMContentLoaded', loadTasks);

// Form submission
taskForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    
    const taskData = {
        title: document.getElementById('taskTitle').value,
        description: document.getElementById('taskDescription').value,
        priority: document.getElementById('taskPriority').value,
        completed: false
    };
    
    try {
        await createTask(taskData);
        taskForm.reset();
        loadTasks();
    } catch (error) {
        alert('Error creating task: ' + error.message);
    }
});

// API Functions
async function loadTasks() {
    try {
        const response = await fetch(`${API_BASE_URL}/tasks`);
        const tasks = await response.json();
        displayTasks(tasks);
        updateStats(tasks);
    } catch (error) {
        console.error('Error loading tasks:', error);
        tasksList.innerHTML = '<p>Error loading tasks</p>';
    }
}

async function createTask(taskData) {
    const response = await fetch(`${API_BASE_URL}/tasks`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(taskData)
    });
    
    if (!response.ok) {
        throw new Error('Failed to create task');
    }
    
    return response.json();
}

async function updateTask(id, updates) {
    const response = await fetch(`${API_BASE_URL}/tasks/${id}`, {
        method: 'PUT',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(updates)
    });
    
    if (!response.ok) {
        throw new Error('Failed to update task');
    }
    
    return response.json();
}

async function deleteTask(id) {
    const response = await fetch(`${API_BASE_URL}/tasks/${id}`, {
        method: 'DELETE'
    });
    
    if (!response.ok) {
        throw new Error('Failed to delete task');
    }
}

// Display Functions
function displayTasks(tasks) {
    if (tasks.length === 0) {
        tasksList.innerHTML = '<p>No tasks found</p>';
        return;
    }
    
    tasksList.innerHTML = tasks.map(task => `
        <div class="task-item ${task.completed ? 'completed' : ''}">
            <div class="task-info">
                <h4>${task.title}</h4>
                <p>${task.description || 'No description'}</p>
                <span class="task-priority priority-${task.priority}">${task.priority}</span>
            </div>
            <div class="task-actions">
                ${!task.completed ? 
                    `<button class="complete-btn" onclick="completeTask(${task.id})">Complete</button>` : 
                    '<span>✓ Completed</span>'
                }
                <button class="delete-btn" onclick="removeTask(${task.id})">Delete</button>
            </div>
        </div>
    `).join('');
}

function updateStats(tasks) {
    const total = tasks.length;
    const completed = tasks.filter(task => task.completed).length;
    const pending = total - completed;
    
    totalTasksEl.textContent = total;
    completedTasksEl.textContent = completed;
    pendingTasksEl.textContent = pending;
}

// Task Actions
async function completeTask(id) {
    try {
        await updateTask(id, { completed: true });
        loadTasks();
    } catch (error) {
        alert('Error completing task: ' + error.message);
    }
}

async function removeTask(id) {
    if (confirm('Are you sure you want to delete this task?')) {
        try {
            await deleteTask(id);
            loadTasks();
        } catch (error) {
            alert('Error deleting task: ' + error.message);
        }
    }
}
EOF

# Create nginx.conf
cat > nginx.conf << 'EOF'
server {
    listen 80;
    server_name localhost;
    
    location / {
        root /usr/share/nginx/html;
        index index.html;
        try_files $uri $uri/ /index.html;
    }
    
    location /api/ {
        proxy_pass http://app:8080/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        add_header Access-Control-Allow-Origin *;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS";
        add_header Access-Control-Allow-Headers "Content-Type, Authorization";
        
        if ($request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin *;
            add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS";
            add_header Access-Control-Allow-Headers "Content-Type, Authorization";
            return 204;
        }
    }
}
EOF

# Create Dockerfile
cat > Dockerfile << 'EOF'
FROM nginx:alpine

COPY src/index.html /usr/share/nginx/html/
COPY src/css/ /usr/share/nginx/html/css/
COPY src/js/ /usr/share/nginx/html/js/
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
EOF
```

### 3. Create Backend Dockerfile
```bash
cd ../2-source-code

cat > Dockerfile << 'EOF'
FROM eclipse-temurin:17-jre-alpine

RUN addgroup -g 1001 -S appuser && \
    adduser -S appuser -G appuser

RUN apk add --no-cache curl

WORKDIR /app

COPY target/task-management-api-*.jar app.jar

RUN chown -R appuser:appuser /app

USER appuser

EXPOSE 8080

ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0"

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
EOF
```

### 4. Setup Docker Compose
```bash
cd ../5-containerization

# Create prometheus.yml
cat > prometheus.yml << 'EOF'
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'task-management-api'
    static_configs:
      - targets: ['app:8080']
    metrics_path: '/actuator/prometheus'
    scrape_interval: 30s

  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
EOF

# Run the application
sudo docker compose up -d
```

## 🐛 Common Issues & Solutions

### Issue 1: OpenJDK Image Not Found
**Error**: `openjdk:17-jre-slim: not found`

**Solution**: Update Dockerfile to use eclipse-temurin
```bash
# Replace in Dockerfile:
FROM openjdk:17-jre-slim
# With:
FROM eclipse-temurin:17-jre-alpine
```

### Issue 2: MySQL Dependency Version Missing
**Error**: `'dependencies.dependency.version' for mysql:mysql-connector-java:jar is missing`

**Solution**: Add version to pom.xml
```bash
sed -i '/<artifactId>mysql-connector-java<\/artifactId>/a\            <version>8.0.33</version>' pom.xml
```

### Issue 3: Container Name Conflicts
**Error**: `Conflict. The container name "/task-prometheus" is already in use`

**Solution**: Remove existing containers
```bash
sudo docker stop task-prometheus task-grafana task-mysql task-app task-frontend 2>/dev/null || true
sudo docker rm task-prometheus task-grafana task-mysql task-app task-frontend 2>/dev/null || true
sudo docker compose up -d
```

### Issue 4: Prometheus Config Mount Error
**Error**: `cannot create subdirectories in "/var/lib/docker/overlay2/.../prometheus.yml": not a directory`

**Solution**: Remove directory and create file
```bash
rm -rf prometheus.yml
cat > prometheus.yml << 'EOF'
global:
  scrape_interval: 15s
scrape_configs:
  - job_name: 'task-management-api'
    static_configs:
      - targets: ['app:8080']
    metrics_path: '/actuator/prometheus'
EOF
```

### Issue 5: Frontend Assets Not Found
**Error**: `"/src/assets": not found`

**Solution**: Create missing directories
```bash
cd 3-frontend
mkdir -p src/assets
# Or remove assets copy from Dockerfile if not needed
```

### Issue 6: Maven Wrapper Missing
**Error**: `"/mvnw": not found`

**Solution**: Use simple Dockerfile or create wrapper
```bash
# Use pre-built JAR approach instead of multi-stage build
# Build JAR first: mvn clean package -DskipTests
# Then use simple Dockerfile
```

## 🔍 Verification Steps

### 1. Check Container Status
```bash
sudo docker compose ps
# All containers should show "Up" or "Running"
```

### 2. Test Services
```bash
# Frontend
curl -I http://localhost:3001
# Should return: HTTP/1.1 200 OK

# Backend Health
curl http://localhost:8080/actuator/health
# Should return: {"status":"UP"}

# Backend API
curl http://localhost:8080/api/tasks
# Should return: [] (empty array)

# Prometheus
curl -I http://localhost:9090
# Should return: HTTP/1.1 200 OK

# Grafana
curl -I http://localhost:3000
# Should return: HTTP/1.1 200 OK
```

### 3. Test Frontend Functionality
1. Open http://localhost:3001 in browser
2. Create a new task using the form
3. Verify task appears in the list
4. Check statistics are updated
5. Test complete/delete functionality

## 📊 Monitoring Access

- **Grafana**: http://localhost:3000
  - Username: `admin`
  - Password: `admin123`
  - Import dashboard ID: 12900 for Spring Boot metrics

- **Prometheus**: http://localhost:9090
  - Check targets: Status → Targets
  - Verify `task-management-api` is UP

## 🔧 Development Commands

```bash
# View logs
sudo docker compose logs -f app
sudo docker compose logs -f frontend

# Restart specific service
sudo docker compose restart app
sudo docker compose restart frontend

# Rebuild and restart
sudo docker compose up -d --build

# Stop all services
sudo docker compose down

# Clean up everything
sudo docker compose down -v
sudo docker system prune -f
```

## 🚀 Production Deployment

For production deployment, see:
- [Kubernetes Deployment Guide](10-documentation/deployment-guide.md)
- [CI/CD Pipeline Setup](8-cicd/)
- [Monitoring Configuration](9-monitoring/)

## 📞 Support

If you encounter issues not covered here:
1. Check container logs: `sudo docker compose logs <service-name>`
2. Verify file permissions: `ls -la`
3. Check Docker daemon: `sudo systemctl status docker`
4. Review network connectivity: `sudo docker network ls`

---

**🎉 Congratulations! Your Task Management System is now running locally with full-stack capabilities, monitoring, and a beautiful dashboard interface.**

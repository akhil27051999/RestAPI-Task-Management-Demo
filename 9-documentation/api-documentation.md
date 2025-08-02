# Task Management API Documentation

## Overview
REST API for managing tasks with full CRUD operations, built with Spring Boot and MySQL.

## Base URL
- **Development**: `http://localhost:8080`
- **Production**: `https://api.taskmanagement.com`

## Authentication
Currently no authentication required. Future versions will implement JWT-based authentication.

## API Endpoints

### Tasks

#### Get All Tasks
```http
GET /api/tasks
```

**Response:**
```json
[
  {
    "id": 1,
    "title": "Complete project documentation",
    "description": "Write comprehensive API documentation",
    "status": "PENDING",
    "createdAt": "2024-01-15T10:30:00",
    "updatedAt": "2024-01-15T10:30:00"
  }
]
```

#### Get Task by ID
```http
GET /api/tasks/{id}
```

**Parameters:**
- `id` (path): Task ID (integer)

**Response:**
```json
{
  "id": 1,
  "title": "Complete project documentation",
  "description": "Write comprehensive API documentation",
  "status": "PENDING",
  "createdAt": "2024-01-15T10:30:00",
  "updatedAt": "2024-01-15T10:30:00"
}
```

**Error Response:**
```json
{
  "status": 404,
  "error": "Not Found",
  "message": "Task not found with id: 1"
}
```

#### Create Task
```http
POST /api/tasks
```

**Request Body:**
```json
{
  "title": "New task title",
  "description": "Task description",
  "status": "PENDING"
}
```

**Response:**
```json
{
  "id": 2,
  "title": "New task title",
  "description": "Task description",
  "status": "PENDING",
  "createdAt": "2024-01-15T11:00:00",
  "updatedAt": "2024-01-15T11:00:00"
}
```

#### Update Task
```http
PUT /api/tasks/{id}
```

**Parameters:**
- `id` (path): Task ID (integer)

**Request Body:**
```json
{
  "title": "Updated task title",
  "description": "Updated description",
  "status": "COMPLETED"
}
```

**Response:**
```json
{
  "id": 1,
  "title": "Updated task title",
  "description": "Updated description",
  "status": "COMPLETED",
  "createdAt": "2024-01-15T10:30:00",
  "updatedAt": "2024-01-15T11:30:00"
}
```

#### Delete Task
```http
DELETE /api/tasks/{id}
```

**Parameters:**
- `id` (path): Task ID (integer)

**Response:** `204 No Content`

### Health & Monitoring

#### Health Check
```http
GET /actuator/health
```

**Response:**
```json
{
  "status": "UP",
  "components": {
    "db": {
      "status": "UP",
      "details": {
        "database": "MySQL",
        "validationQuery": "isValid()"
      }
    }
  }
}
```

#### Metrics
```http
GET /actuator/metrics
```

#### Prometheus Metrics
```http
GET /actuator/prometheus
```

## Data Models

### Task
```json
{
  "id": "integer (auto-generated)",
  "title": "string (required, max 255 chars)",
  "description": "string (optional, max 1000 chars)",
  "status": "enum (PENDING, IN_PROGRESS, COMPLETED, CANCELLED)",
  "createdAt": "datetime (auto-generated)",
  "updatedAt": "datetime (auto-updated)"
}
```

### Task Status Values
- `PENDING`: Task is created but not started
- `IN_PROGRESS`: Task is currently being worked on
- `COMPLETED`: Task is finished
- `CANCELLED`: Task is cancelled

## HTTP Status Codes
- `200 OK`: Successful GET/PUT request
- `201 Created`: Successful POST request
- `204 No Content`: Successful DELETE request
- `400 Bad Request`: Invalid request data
- `404 Not Found`: Resource not found
- `500 Internal Server Error`: Server error

## Error Response Format
```json
{
  "timestamp": "2024-01-15T12:00:00",
  "status": 400,
  "error": "Bad Request",
  "message": "Validation failed",
  "path": "/api/tasks"
}
```

## Rate Limiting
- **Development**: No limits
- **Production**: 100 requests per minute per IP

## Examples

### cURL Examples

**Create a task:**
```bash
curl -X POST http://localhost:8080/api/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Learn Kubernetes",
    "description": "Complete Kubernetes tutorial",
    "status": "PENDING"
  }'
```

**Get all tasks:**
```bash
curl http://localhost:8080/api/tasks
```

**Update a task:**
```bash
curl -X PUT http://localhost:8080/api/tasks/1 \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Learn Kubernetes",
    "description": "Complete Kubernetes tutorial",
    "status": "COMPLETED"
  }'
```

**Delete a task:**
```bash
curl -X DELETE http://localhost:8080/api/tasks/1
```

### JavaScript Examples

**Using Fetch API:**
```javascript
// Create task
const createTask = async () => {
  const response = await fetch('/api/tasks', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      title: 'New Task',
      description: 'Task description',
      status: 'PENDING'
    })
  });
  return response.json();
};

// Get all tasks
const getTasks = async () => {
  const response = await fetch('/api/tasks');
  return response.json();
};
```

## SDKs and Libraries
Currently no official SDKs available. Standard HTTP clients can be used with any programming language.

## Changelog
- **v1.0.0**: Initial release with basic CRUD operations
- **v1.1.0**: Added health checks and metrics endpoints
- **v1.2.0**: Enhanced error handling and validation

